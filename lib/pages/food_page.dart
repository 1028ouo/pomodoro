import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../services/recipe_service.dart';
import 'food_detail_page.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({Key? key}) : super(key: key);

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _userRecipes;
  String _searchQuery = '';
  bool _isLoading = false;
  // 添加 TextEditingController 作為成員變數
  late TextEditingController _searchController;
  // 添加 ScrollController 用於監聽滾動
  late ScrollController _scrollController;
  // 控制搜尋欄顯示狀態
  bool _showSearchBar = true;
  // 紀錄上次滾動位置
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // 初始化 TextEditingController
    _searchController = TextEditingController();
    // 初始化 ScrollController
    _scrollController = ScrollController();
    // 添加滾動監聽器
    _scrollController.addListener(_scrollListener);
    _loadUserRecipes();
  }

  @override
  void dispose() {
    // 釋放 TextEditingController 資源
    _searchController.dispose();
    // 移除滾動監聽器並釋放 ScrollController 資源
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滾動監聽函數
  void _scrollListener() {
    // 判斷滾動方向
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _scrollController.offset > _lastScrollOffset &&
        _showSearchBar) {
      // 向下滾動，隱藏搜尋欄
      setState(() {
        _showSearchBar = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        _scrollController.offset < _lastScrollOffset &&
        !_showSearchBar) {
      // 向上滾動，顯示搜尋欄
      setState(() {
        _showSearchBar = true;
      });
    }

    // 更新上次滾動位置
    _lastScrollOffset = _scrollController.offset;
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
      // 移除 AppBar
      extendBodyBehindAppBar: true, // 保留此屬性以確保內容可以延伸到頂部
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_pic/recipe_home.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 搜尋欄，使用 AnimatedContainer 實現動畫效果
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _showSearchBar ? 92 : 0, // 包含 Padding 的高度
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // 增加邊距
                  child: Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // 半透明白色背景
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        // 使用懸浮標籤行為，當獲得焦點或有文字時會將標籤移到上方
                        floatingLabelBehavior:
                            FloatingLabelBehavior.never, // 永不顯示懸浮標籤
                        // 根據焦點狀態或文字輸入狀態決定是否顯示標籤
                        labelText:
                            _searchController.text.isNotEmpty ? null : '搜尋我的食譜',
                        labelStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: '輸入食譜關鍵字',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                        ), // 圖標顏色調整
                        // 添加條件式清除按鈕
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.amber[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      // 清空 controller 的文字
                                      _searchController.clear();
                                    });
                                    FocusScope.of(
                                      context,
                                    ).unfocus(); // 選擇性地取消焦點
                                  },
                                )
                                : null,
                        border: InputBorder.none, // 去除原有邊框
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 15.0,
                        ), // 調整內邊距
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      // 新增獲得焦點時的行為，讓標籤消失
                      onTap: () {
                        setState(() {
                          // 強制更新 UI 以應用新的裝飾設定
                        });
                      },
                      // 使用類別成員變數的 controller
                      controller: _searchController,
                    ),
                  ),
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
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  controller: _scrollController, // 使用滾動控制器
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 15,
                                            sigmaY: 15,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.brown.shade50
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.brown.withOpacity(
                                                  0.3,
                                                ),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    AspectRatio(
                                                      aspectRatio: 1.5,
                                                      child: Image.network(
                                                        recipe['imageUrl'] ??
                                                            '',
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
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
                                                              color: Colors
                                                                  .grey[200]!
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .restaurant,
                                                                size: 50,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    8.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        recipe['title'] ??
                                                            '未命名食譜',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.brown,
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 2.0,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              offset: Offset(
                                                                1,
                                                                1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      SizedBox(height: 35),

                                                      if (recipe['obtainedAt'] !=
                                                          null)
                                                        Align(
                                                          alignment:
                                                              Alignment
                                                                  .bottomRight,
                                                          child: Text(
                                                            '獲得於: ${_formatDate(recipe['obtainedAt'])}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.grey,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              shadows: [
                                                                Shadow(
                                                                  blurRadius:
                                                                      1.5,
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.5,
                                                                      ),
                                                                  offset:
                                                                      Offset(
                                                                        0.5,
                                                                        0.5,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
