import 'package:flutter/material.dart';
import 'dart:ui'; // 新增這行以使用 ImageFilter
import 'timer_page.dart';
import 'food_page.dart';
import 'task_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // 追蹤當前選中的頁面索引

  // 頁面列表
  final List<Widget> _pages = [
    const HomeContent(), // 主頁內容
    const FoodPage(), // 食物頁面
    const TaskPage(), // 待辦事項頁面
    const ProfilePage(), // 個人檔案頁面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 讓內容延伸到底部導航欄下方
      body: _pages[_currentIndex],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 增加模糊程度
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // 降低不透明度，增加霧感
              border: Border.all(
                color: Colors.white.withOpacity(0.2), // 添加細微的邊框
                width: 0.5,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                elevation: 0, // 移除陰影
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent, // 保持底部導航欄透明
                showSelectedLabels: false, // 確保不顯示標籤
                showUnselectedLabels: false,
                selectedItemColor:
                    Theme.of(context).colorScheme.primary, // 選中項目顏色
                unselectedItemColor: const Color.fromARGB(
                  255,
                  93,
                  91,
                  91,
                ), // 未選中項目顏色
                selectedIconTheme: const IconThemeData(size: 32), // 選中圖示大一點
                unselectedIconTheme: const IconThemeData(size: 28),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book),
                    label: '圖鑑',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.playlist_add),
                    label: '待辦事項',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle),
                    label: '個人檔案',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
