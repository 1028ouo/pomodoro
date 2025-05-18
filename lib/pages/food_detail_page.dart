import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/food_model.dart';
import '../services/food_service.dart';

class FoodDetailPage extends StatefulWidget {
  final int recipeId;

  const FoodDetailPage({Key? key, required this.recipeId}) : super(key: key);

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Future<Food> _futureRecipeDetails;
  final FoodService _foodService = FoodService();

  @override
  void initState() {
    super.initState();
    _futureRecipeDetails = _foodService.getRecipeDetails(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('食譜詳情')),
      body: FutureBuilder<Food>(
        future: _futureRecipeDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final recipe = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 食譜圖片
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      recipe.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),

                  // 食譜標題和基本資訊
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              avatar: Icon(Icons.access_time, size: 16),
                              label: Text('${recipe.readyInMinutes} 分鐘'),
                            ),
                            SizedBox(width: 8),
                            Chip(
                              avatar: Icon(Icons.people, size: 16),
                              label: Text('${recipe.servings} 人份'),
                            ),
                          ],
                        ),

                        // 食譜標籤
                        Wrap(
                          spacing: 8,
                          children: [
                            if (recipe.vegetarian) Chip(label: Text('素食')),
                            if (recipe.vegan) Chip(label: Text('純素')),
                            if (recipe.glutenFree) Chip(label: Text('無麩質')),
                            if (recipe.dairyFree) Chip(label: Text('無乳製品')),
                          ],
                        ),

                        // 食譜摘要
                        SizedBox(height: 16),
                        Text(
                          '摘要',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Html(data: recipe.summary),

                        // 食材列表
                        SizedBox(height: 16),
                        Text(
                          '食材',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: recipe.ingredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = recipe.ingredients[index];
                            return ListTile(
                              leading:
                                  ingredient.image.isNotEmpty
                                      ? Image.network(
                                        'https://spoonacular.com/cdn/ingredients_100x100/${ingredient.image}',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                          );
                                        },
                                      )
                                      : Icon(Icons.food_bank, size: 50),
                              title: Text(
                                ingredient.original,
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          },
                        ),

                        // 烹飪步驟
                        SizedBox(height: 16),
                        Text(
                          '烹飪步驟',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        recipe.analyzedInstructions.isEmpty
                            ? (recipe.instructions.isEmpty
                                ? Text('沒有提供烹飪步驟。')
                                : Html(data: recipe.instructions))
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: recipe.analyzedInstructions.length,
                              itemBuilder: (context, instructionIndex) {
                                final instruction =
                                    recipe
                                        .analyzedInstructions[instructionIndex];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (instruction.name.isNotEmpty) ...[
                                      Text(
                                        instruction.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: instruction.steps.length,
                                      itemBuilder: (context, stepIndex) {
                                        final step =
                                            instruction.steps[stepIndex];
                                        return Card(
                                          margin: EdgeInsets.only(bottom: 16.0),
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 步驟標題
                                                Text(
                                                  '步驟 ${step.number}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Divider(),
                                                SizedBox(height: 8),

                                                // 步驟說明
                                                Text(
                                                  step.step,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(height: 12),

                                                // 所需食材
                                                if (step
                                                    .ingredients
                                                    .isNotEmpty) ...[
                                                  Text(
                                                    '所需食材:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                        step.ingredients.map((
                                                          ingredient,
                                                        ) {
                                                          return Chip(
                                                            avatar:
                                                                ingredient
                                                                        .image
                                                                        .isNotEmpty
                                                                    ? CircleAvatar(
                                                                      backgroundImage: NetworkImage(
                                                                        ingredient.image.startsWith(
                                                                              'http',
                                                                            )
                                                                            ? ingredient.image
                                                                            : 'https://spoonacular.com/cdn/ingredients_100x100/${ingredient.image}',
                                                                      ),
                                                                      onBackgroundImageError:
                                                                          (
                                                                            exception,
                                                                            stackTrace,
                                                                          ) {},
                                                                    )
                                                                    : null,
                                                            label: Text(
                                                              ingredient
                                                                  .localizedName,
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                  SizedBox(height: 12),
                                                ],

                                                // 所需設備
                                                if (step
                                                    .equipment
                                                    .isNotEmpty) ...[
                                                  Text(
                                                    '所需廚具:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children:
                                                        step.equipment.map((
                                                          equipment,
                                                        ) {
                                                          return Chip(
                                                            avatar:
                                                                equipment
                                                                        .image
                                                                        .isNotEmpty
                                                                    ? CircleAvatar(
                                                                      backgroundImage:
                                                                          NetworkImage(
                                                                            'https://spoonacular.com/cdn/equipment_100x100/${equipment.image}',
                                                                          ),
                                                                      onBackgroundImageError:
                                                                          (
                                                                            exception,
                                                                            stackTrace,
                                                                          ) {},
                                                                    )
                                                                    : null,
                                                            label: Text(
                                                              equipment
                                                                  .localizedName,
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                  SizedBox(height: 12),
                                                ],

                                                // 時間
                                                if (step.length != null) ...[
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.timer,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '需時: ${step.length!.number} ${step.length!.unit}',
                                                        style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),

                        // 來源連結
                        if (recipe.sourceUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              children: [
                                Text('資料來源: '),
                                Expanded(child: Text(recipe.sourceUrl)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('無法載入食譜詳情'));
          }
        },
      ),
    );
  }
}
