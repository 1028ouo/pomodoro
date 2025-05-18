import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc =
            await _db.collection("users").doc(currentUser.uid).get();

        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
          });
        } else {
          // 用戶文檔不存在，創建新的用戶資料
          Map<String, dynamic> newUserData = {
            'username': currentUser.displayName ?? '使用者',
            'email': currentUser.email ?? '',
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'birthday': '',
            'photoURL': currentUser.photoURL ?? '',
          };

          // 儲存到 Firestore
          await _db.collection("users").doc(currentUser.uid).set(newUserData);

          // 更新 UI
          setState(() {
            userData = newUserData;
          });

          // 提示用戶已創建檔案
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已創建您的個人檔案'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print("讀取使用者資料時發生錯誤: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('讀取個人資料失敗: $e')));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData == null || _auth.currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 100),
            SizedBox(height: 20),
            Text(
              '尚未登入',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '請先登入以查看您的個人資料',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 獲取並格式化使用者資料
    String username = userData!['username'] ?? '未知用戶';
    String email = _auth.currentUser?.email ?? '未設定郵箱';
    String joinedAt = userData!['joinedAt'] ?? '';
    String birthday = userData!['birthday'] ?? '';
    int totalFocusTime = userData!['totalFocusTime'] ?? 0;
    int streakDays = userData!['streakDays'] ?? 0;
    int weeklyFocusTime = userData!['weeklyFocusTime'] ?? 0;
    int completedPomodoros = userData!['completedPomodoros'] ?? 0;

    // 格式化日期顯示
    String formattedJoinedDate = '未知';
    String formattedBirthday = '未設定';

    if (joinedAt.isNotEmpty) {
      try {
        DateTime joinDate = DateTime.parse(joinedAt);
        formattedJoinedDate =
            '${joinDate.year}年${joinDate.month}月${joinDate.day}日';
      } catch (e) {
        // 處理日期解析錯誤
      }
    }

    if (birthday.isNotEmpty) {
      try {
        DateTime birthDate = DateTime.parse(birthday);
        formattedBirthday =
            '${birthDate.year}年${birthDate.month}月${birthDate.day}日';
      } catch (e) {
        // 處理日期解析錯誤
      }
    }

    // 將秒數轉換為小時:分鐘格式
    int hours = totalFocusTime ~/ 3600;
    int minutes = (totalFocusTime % 3600) ~/ 60;
    String formattedFocusTime = '$hours 小時 $minutes 分鐘';

    // 將本週學習時間轉換為小時:分鐘格式
    int weeklyHours = weeklyFocusTime ~/ 3600;
    int weeklyMinutes = (weeklyFocusTime % 3600) ~/ 60;
    String formattedWeeklyTime = '$weeklyHours 小時 $weeklyMinutes 分鐘';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 頭像和用戶名區域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 統計數據區塊
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('專注時間', formattedFocusTime, Icons.timer),
                  const VerticalDivider(thickness: 1, color: Colors.grey),
                  _buildStatColumn(
                    '加入日期',
                    formattedJoinedDate,
                    Icons.calendar_today,
                  ),
                ],
              ),
            ),

            const Divider(),

            // 個人資訊區域 - 標題
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '個人資訊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 個人資訊項目列表
            _buildInfoListTile(Icons.person, '使用者名稱', username),
            _buildInfoListTile(Icons.email, '電子郵件', email),
            _buildInfoListTile(Icons.cake, '生日', formattedBirthday),
            _buildInfoListTile(
              Icons.event_available,
              '加入日期',
              formattedJoinedDate,
            ),

            const Divider(),

            // 統計區域 - 標題
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '學習統計',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 總專注時間卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.blue, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '總專注時間',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                formattedFocusTime,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    const Text('進度 70%', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 新增 - 其他學習統計卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 連續學習天數
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '連續學習天數',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$streakDays 天',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 本週學習時間
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_view_week,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '本週學習時間',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                formattedWeeklyTime,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 完成的番茄鐘數量
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.purple,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '完成的番茄鐘',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$completedPomodoros 個',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 添加登出按鈕
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  '登出',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 構建統計數據列
  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 構建信息列表項
  Widget _buildInfoListTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
