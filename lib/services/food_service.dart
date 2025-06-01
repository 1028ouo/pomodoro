import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../models/food_model.dart';
import 'recipe_service.dart';

class FoodService {
  final FirebaseService _firebaseService = FirebaseService();

  // 搜尋食譜但只返回使用者已獲得的
  Future<FoodSearchResponse> searchRecipes({
    required String query,
    int number = 50,
    bool addRecipeInformation = true,
  }) async {
    // 獲取使用者的食譜ID
    final userRecipeIds = await _firebaseService.getUserRecipeIds();

    if (userRecipeIds.isEmpty) {
      // 如果使用者沒有食譜，返回空結果
      return FoodSearchResponse(
        results: [],
        totalResults: 0,
        offset: 0,
        number: 0,
      );
    }

    // 構建API請求
    final url = Uri.parse(
      '${EnvConfig.spoonacularBaseUrl}/recipes/complexSearch?query=$query&number=$number&addRecipeInformation=$addRecipeInformation&apiKey=${EnvConfig.spoonacularApiKey}',
    );

    final request = http.Request('GET', url);
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final allRecipes = FoodSearchResponse.fromJson(json.decode(responseData));

      // 過濾結果，只保留使用者擁有的食譜
      final filteredResults =
          allRecipes.results
              .where((recipe) => userRecipeIds.contains(recipe.id))
              .toList();

      return FoodSearchResponse(
        results: filteredResults,
        totalResults: filteredResults.length,
        offset: 0,
        number: filteredResults.length,
      );
    } else {
      throw Exception('Failed to load recipes: ${response.reasonPhrase}');
    }
  }

  // 獲取食譜詳情
  Future<Food> getRecipeDetails(int recipeId) async {
    final url = Uri.parse(
      '${EnvConfig.spoonacularBaseUrl}/recipes/$recipeId/information?apiKey=${EnvConfig.spoonacularApiKey}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Food.fromJson(json.decode(response.body));
    } else {
      throw Exception('無法載入食譜詳細資訊: ${response.reasonPhrase}');
    }
  }

  // 獲取隨機食譜
  Future<Food> getRandomRecipe() async {
    final url = Uri.parse(
      '${EnvConfig.spoonacularBaseUrl}/recipes/random?number=1&apiKey=${EnvConfig.spoonacularApiKey}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['recipes'] != null && data['recipes'].isNotEmpty) {
        return Food.fromJson(data['recipes'][0]);
      } else {
        throw Exception('無法獲取隨機食譜');
      }
    } else {
      throw Exception('獲取隨機食譜失敗: ${response.reasonPhrase}');
    }
  }
}
