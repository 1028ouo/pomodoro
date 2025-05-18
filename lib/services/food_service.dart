import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../models/food_model.dart';

class FoodService {
  Future<FoodSearchResponse> searchRecipes({
    required String query,
    int number = 10,
    bool addRecipeInformation = true,
  }) async {
    final url = Uri.parse(
      '${EnvConfig.spoonacularBaseUrl}/recipes/complexSearch?query=$query&number=$number&addRecipeInformation=$addRecipeInformation&apiKey=${EnvConfig.spoonacularApiKey}',
    );

    final request = http.Request('GET', url);
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      return FoodSearchResponse.fromJson(json.decode(responseData));
    } else {
      throw Exception('Failed to load recipes: ${response.reasonPhrase}');
    }
  }

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
}
