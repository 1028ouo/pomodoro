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
  bool _hasNetworkError = false; // 網路錯誤狀態追蹤
  String _errorMessage = ''; // 新增：儲存具體錯誤訊息
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  bool _showSearchBar = true;
  // 紀錄上次滾動位置
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadUserRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滾動監聽函數
  void _scrollListener() {
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
      _hasNetworkError = false; // 重置網路錯誤狀態
      _errorMessage = ''; // 重置錯誤訊息
    });

    try {
      _userRecipes = _firebaseService.getUserRecipes();
    } catch (e) {
      print('載入食譜失敗: $e');
      setState(() {
        _hasNetworkError = true; // 設置網路錯誤狀態
        // 設置具體的錯誤訊息
        if (e.toString().contains('network')) {
          _errorMessage = '網路連線問題，請檢查您的網路設定';
        } else if (e.toString().contains('permission')) {
          _errorMessage = '權限問題，無法存取資料';
        } else if (e.toString().contains('timeout')) {
          _errorMessage = '連線逾時，請稍後再試';
        } else {
          _errorMessage = '發生錯誤：${e.toString()}';
        }
      });
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

  // 顯示網路錯誤UI
  Widget _buildNetworkErrorView() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage.contains('網路')
                  ? Icons.wifi_off
                  : Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 24),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : '無法載入資料',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '請檢查您的連線狀態後重試',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _loadUserRecipes();
              },
              icon: Icon(Icons.refresh),
              label: Text('重新整理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
              // 搜尋欄
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _showSearchBar ? 92 : 0,
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
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
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelText:
                            _searchController.text.isNotEmpty ? null : '搜尋我的食譜',
                        labelStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: '輸入食譜關鍵字',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.black),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 15.0,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
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
                        : _hasNetworkError
                        ? _buildNetworkErrorView() // 顯示網路錯誤視圖
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
                                // 處理其他錯誤
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
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          _loadUserRecipes();
                                        },
                                        child: Text('重試'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.brown.shade200,
                                        ),
                                      ),
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
                                  controller: _scrollController,
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
                                                              .withOpacity(0.5),
                                                          child: Icon(
                                                            Icons.restaurant,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  ),
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
