import 'package:flutter/material.dart';

import '../models/food_model.dart';
import '../services/food_service.dart';
import '../services/firebase_service.dart';
import 'food_detail_page.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({Key? key}) : super(key: key);

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final FoodService _foodService = FoodService();
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _userRecipes;
  String _searchQuery = '';
  bool _isLoading = false;
  // 添加 TextEditingController 作為成員變數
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 初始化 TextEditingController
    _searchController = TextEditingController();
    _loadUserRecipes();
  }

  @override
  void dispose() {
    // 釋放 TextEditingController 資源
    _searchController.dispose();
    super.dispose();
  }

  // 載入使用者食譜
  Future<void> _loadUserRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _userRecipes = _firebaseService.getUserRecipes();
    } catch (e) {
      print('載入食譜失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 過濾使用者食譜
  List<Map<String, dynamic>> _filterRecipes(
    List<Map<String, dynamic>> recipes,
  ) {
    if (_searchQuery.isEmpty) {
      return recipes;
    }

    return recipes
        .where(
          (recipe) => recipe['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的食譜收藏'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 搜尋欄
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '搜尋我的食譜',
                  hintText: '輸入食譜關鍵字',
                  prefixIcon: Icon(Icons.search),
                  // 添加條件式清除按鈕
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                // 清空 controller 的文字
                                _searchController.clear();
                              });
                              FocusScope.of(context).unfocus(); // 選擇性地取消焦點
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                // 使用類別成員變數的 controller
                controller: _searchController,
              ),
            ),

            // 主要內容區域
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: () async {
                          await _loadUserRecipes();
                        },
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _userRecipes,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 16),
                                    Text('錯誤: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data!.isNotEmpty) {
                              final recipes = _filterRecipes(snapshot.data!);

                              if (recipes.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '沒有符合「$_searchQuery」的食譜',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: EdgeInsets.all(16.0),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: recipes.length,
                                itemBuilder: (context, index) {
                                  final recipe = recipes[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => FoodDetailPage(
                                                recipeId: recipe['id'],
                                              ),
                                        ),
                                      ).then((_) {
                                        // 從食譜詳情頁返回時重新載入食譜
                                        _loadUserRecipes();
                                      });
                                    },
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              AspectRatio(
                                                aspectRatio: 1.5,
                                                child: Image.network(
                                                  recipe['imageUrl'] ?? '',
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                          Icons.restaurant,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.emoji_events,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '獲得',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recipe['title'] ?? '未命名食譜',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '點擊查看詳情',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                if (recipe['obtainedAt'] !=
                                                    null)
                                                  Text(
                                                    '獲得於: ${_formatDate(recipe['obtainedAt'])}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '尚未獲得任何食譜',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '完成番茄鐘來獲取新食譜！',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // 格式化日期
  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return '未知時間';

      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.toDate != null) {
        // Firestore Timestamp
        date = timestamp.toDate();
      } else {
        return '未知時間';
      }

      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
    } catch (e) {
      return '未知時間';
    }
  }
}
