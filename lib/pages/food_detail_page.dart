import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:palette_generator/palette_generator.dart';
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

  // 存儲提取的顏色
  Color _primaryColor = Colors.brown.shade300;
  Color _secondaryColor = Colors.brown.shade100;
  Color _textColor = Colors.brown.shade800;
  bool _colorsExtracted = false;

  @override
  void initState() {
    super.initState();
    _futureRecipeDetails = _foodService.getRecipeDetails(widget.recipeId);
  }

  // 從圖片提取顏色
  Future<void> _extractColorsFromImage(String imageUrl) async {
    if (_colorsExtracted) return;

    try {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
            NetworkImage(imageUrl),
            size: Size(100, 100), // 減小尺寸以加快分析速度
            maximumColorCount: 10,
          );

      if (paletteGenerator.dominantColor != null) {
        final Color dominantColor = paletteGenerator.dominantColor!.color;
        final HSLColor hslDominant = HSLColor.fromColor(dominantColor);

        // 生成協調的顏色方案 - 確保 primary 較深，secondary 較淺
        final Color primaryColor =
            hslDominant.withLightness(0.3).toColor(); // 較深的顏色
        final Color secondaryColor =
            hslDominant.withLightness(0.85).toColor(); // 較淺的顏色
        final Color textColor =
            hslDominant.withLightness(0.2).toColor(); // 更深的顏色，適合文字

        setState(() {
          _primaryColor = primaryColor;
          _secondaryColor = secondaryColor;
          _textColor = textColor;
          _colorsExtracted = true;
        });
      }
    } catch (e) {
      print('提取顏色時出錯: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '食譜詳情',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        elevation: 0,
        backgroundColor: _secondaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_pic/recipe_detail.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.lighten,
            ),
          ),
        ),
        child: FutureBuilder<Food>(
          future: _futureRecipeDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在載入美味食譜...',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      '錯誤: ${snapshot.error}',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futureRecipeDetails = _foodService.getRecipeDetails(
                            widget.recipeId,
                          );
                        });
                      },
                      child: Text('重新嘗試'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              final recipe = snapshot.data!;

              // 提取顏色
              if (!_colorsExtracted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _extractColorsFromImage(recipe.image);
                });
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 食譜圖片 - 改進為更美觀的設計
                    Stack(
                      children: [
                        Hero(
                          tag: 'recipe-${recipe.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                            child: Image.network(
                              recipe.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // 時間和份量標籤
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${recipe.readyInMinutes} 分鐘',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${recipe.servings} 人份',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 食譜標題和基本資訊
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 16),

                          // 食譜標籤 - 美化
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (recipe.vegetarian)
                                _buildTag(
                                  Icons.eco,
                                  '素食',
                                  Colors.green.shade700,
                                ),
                              if (recipe.vegan)
                                _buildTag(
                                  Icons.spa,
                                  '純素',
                                  Colors.teal.shade700,
                                ),
                              if (recipe.glutenFree)
                                _buildTag(
                                  Icons.grain_outlined,
                                  '無麩質',
                                  Colors.amber.shade800,
                                ),
                              if (recipe.dairyFree)
                                _buildTag(
                                  Icons.no_drinks,
                                  '無乳製品',
                                  Colors.blue.shade700,
                                ),
                            ],
                          ),

                          // 食譜摘要
                          SizedBox(height: 24),
                          _buildSectionTitle('摘要', Icons.description),
                          Container(
                            margin: EdgeInsets.only(top: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Html(
                              data: recipe.summary,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(16),
                                  lineHeight: LineHeight(1.6),
                                ),
                                "a": Style(
                                  color: _primaryColor,
                                  textDecoration: TextDecoration.none,
                                ),
                              },
                            ),
                          ),

                          // 食材列表
                          SizedBox(height: 24),
                          _buildSectionTitle('食材', Icons.restaurant),
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
                          SizedBox(height: 24),
                          _buildSectionTitle('烹飪步驟', Icons.kitchen),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (instruction.name.isNotEmpty) ...[
                                        Container(
                                          margin: EdgeInsets.only(bottom: 12),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _primaryColor.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            instruction.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: instruction.steps.length,
                                        itemBuilder: (context, stepIndex) {
                                          final step =
                                              instruction.steps[stepIndex];
                                          return Card(
                                            margin: EdgeInsets.only(
                                              bottom: 16.0,
                                            ),
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              side: BorderSide(
                                                color: _primaryColor
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    _secondaryColor.withOpacity(
                                                      0.3,
                                                    ),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // 步驟標題
                                                    Text(
                                                      'Step ${stepIndex + 1}',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _primaryColor,
                                                      ),
                                                    ),
                                                    Divider(
                                                      color: _primaryColor
                                                          .withOpacity(0.3),
                                                      thickness: 1,
                                                    ),
                                                    SizedBox(height: 12),

                                                    // 步驟說明
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        12,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: _primaryColor
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            blurRadius: 5,
                                                            offset: Offset(
                                                              0,
                                                              2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        step.step,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          height: 1.5,
                                                          color: _textColor
                                                              .withOpacity(0.9),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),

                                                    // 所需食材
                                                    if (step
                                                        .ingredients
                                                        .isNotEmpty) ...[
                                                      _buildStepSectionTitle(
                                                        '所需食材:',
                                                        Icons.restaurant,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          8,
                                                        ),
                                                        child: Wrap(
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
                                                                          : CircleAvatar(
                                                                            backgroundColor:
                                                                                _primaryColor,
                                                                            child: Icon(
                                                                              Icons.restaurant,
                                                                              color:
                                                                                  Colors.white,
                                                                              size:
                                                                                  16,
                                                                            ),
                                                                          ),
                                                                  label: Text(
                                                                    ingredient
                                                                        .localizedName,
                                                                    style: TextStyle(
                                                                      color:
                                                                          _textColor,
                                                                    ),
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  side: BorderSide(
                                                                    color: _primaryColor
                                                                        .withOpacity(
                                                                          0.3,
                                                                        ),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                        ),
                                                      ),
                                                      SizedBox(height: 16),
                                                    ],

                                                    // 所需設備
                                                    if (step
                                                        .equipment
                                                        .isNotEmpty) ...[
                                                      _buildStepSectionTitle(
                                                        '所需廚具:',
                                                        Icons.kitchen,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          8,
                                                        ),
                                                        child: Wrap(
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
                                                                            backgroundImage: NetworkImage(
                                                                              'https://spoonacular.com/cdn/equipment_100x100/${equipment.image}',
                                                                            ),
                                                                            onBackgroundImageError:
                                                                                (
                                                                                  exception,
                                                                                  stackTrace,
                                                                                ) {},
                                                                          )
                                                                          : CircleAvatar(
                                                                            backgroundColor:
                                                                                _primaryColor,
                                                                            child: Icon(
                                                                              Icons.kitchen,
                                                                              color:
                                                                                  Colors.white,
                                                                              size:
                                                                                  16,
                                                                            ),
                                                                          ),
                                                                  label: Text(
                                                                    equipment
                                                                        .localizedName,
                                                                    style: TextStyle(
                                                                      color:
                                                                          _textColor,
                                                                    ),
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  side: BorderSide(
                                                                    color: _primaryColor
                                                                        .withOpacity(
                                                                          0.3,
                                                                        ),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                        ),
                                                      ),
                                                      SizedBox(height: 16),
                                                    ],

                                                    // 時間
                                                    if (step.length !=
                                                        null) ...[
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: _primaryColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.timer,
                                                              size: 18,
                                                              color:
                                                                  _primaryColor,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              '需時: ${step.length!.number} ${step.length!.unit}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    _textColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
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
      ),
    );
  }

  // 創建標籤小部件
  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.brown[900] ?? color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 創建區塊標題小部件
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  // 創建步驟小標題部件
  Widget _buildStepSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 18),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }
}
