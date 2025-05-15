import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // 追蹤當前選中的頁面索引

  // 頁面列表
  final List<Widget> _pages = [
    // 主頁內容
    const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 100),
          SizedBox(height: 20),
          Text(
            '歡迎使用 Pomodoro!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: null, // 這裡可以開始一個番茄鐘
            child: Text('開始專注'),
          ),
        ],
      ),
    ),
    // 設定頁面內容
    const Center(
      child: Text(
        '個人檔案',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  // 處理登出
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 顯示對話框確認登出
      bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('確認登出'),
              content: const Text('您確定要登出嗎？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('登出'),
                ),
              ],
            ),
      );

      // 用戶取消登出
      if (shouldLogout != true) {
        return;
      }

      // 顯示登出中的提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登出中...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 執行登出操作
      await FirebaseAuth.instance.signOut();

      // 登出成功後，強制導航到登入頁面
      if (context.mounted) {
        // 使用 Navigator.pushNamedAndRemoveUntil 清除所有路由並導航到登入頁面
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      // 處理錯誤
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登出時發生錯誤: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        actions: [
          // 登出按鈕
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '登出',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
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
          backgroundColor: Colors.white,
          showSelectedLabels: false, // 確保不顯示標籤
          showUnselectedLabels: false,
          selectedItemColor: Theme.of(context).colorScheme.primary, // 選中項目顏色
          unselectedItemColor: Colors.grey, // 未選中項目顏色
          selectedIconTheme: const IconThemeData(size: 32), // 選中圖示大一點
          unselectedIconTheme: const IconThemeData(size: 28),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
