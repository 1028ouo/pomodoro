import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService(); // 添加 AuthService 實例
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // 添加動畫控制器
  late AnimationController _animationController;
  late Animation<double> _rabbitSwingAnimation;
  late Animation<double> _catSwingAnimation;
  late Animation<double> _rabbitPositionAnimation;
  late Animation<double> _catPositionAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // 初始化動畫控制器
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 搖擺動畫 (旋轉角度的變化)
    _rabbitSwingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.8, end: -0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: -0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.6, end: -0.5), weight: 30),
    ]).animate(_animationController);

    _catSwingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.5), weight: 30),
    ]).animate(_animationController);

    // 位置動畫 (從畫面外到當前位置)
    _rabbitPositionAnimation = Tween<double>(begin: -100, end: -20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _catPositionAnimation = Tween<double>(begin: -100, end: -32).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // 頁面加載後開始播放動畫
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          // 隨機生成一個頭像 ID (1-10)
          int randomPicId = 1 + (DateTime.now().millisecondsSinceEpoch % 10);
          String profilePicId = 'pic_$randomPicId';

          Map<String, dynamic> newUserData = {
            'username': currentUser.displayName ?? '使用者',
            'email': currentUser.email ?? '',
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'birthday': '',
            'profilePicId': profilePicId, // 儲存頭像 ID 而非 URL
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

  // 處理生日編輯
  Future<void> _editBirthday(BuildContext context) async {
    // 檢查當前生日是否為空
    String currentBirthday = userData?['birthday'] ?? '';
    if (currentBirthday.isNotEmpty) {
      // 如果已經有生日，顯示提示不能修改
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('生日資料已設定，無法修改'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 顯示日期選擇器
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1), // 設定初始日期
      firstDate: DateTime(1900), // 最早可選日期
      lastDate: DateTime.now(), // 最晚可選日期為今天
      helpText: '選擇您的生日',
      cancelText: '取消',
      confirmText: '確認',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 格式化日期為 ISO 字符串
      String formattedDate = pickedDate.toIso8601String();

      // 使用 AuthService 更新生日
      final result = await _authService.updateBirthday(formattedDate);

      if (context.mounted) {
        if (result['success']) {
          // 更新成功，刷新資料
          await _fetchUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // 更新失敗
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
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

    // 獲取頭像 ID
    String profilePicId = userData!['profilePicId'] ?? 'pic_1';

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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_pic/profile_home.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 頭像和用戶名區域
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    // 顯示頭像 - 使用本地資源而非可上傳
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.brown.shade100, // 修改為棕色調
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/profile_pic/$profilePicId.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // 兔子 (使用動畫)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Positioned(
                              left: _rabbitPositionAnimation.value,
                              bottom: -5,
                              child: Transform.rotate(
                                angle: _rabbitSwingAnimation.value,
                                child: Image.asset(
                                  'assets/widget_pic/rabbit.png',
                                  height: 65,
                                ),
                              ),
                            );
                          },
                        ),
                        // 咪咪 (使用動畫)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Positioned(
                              right: _catPositionAnimation.value,
                              top: -5,
                              child: Transform.rotate(
                                angle: _catSwingAnimation.value,
                                child: Image.asset(
                                  'assets/widget_pic/cat.png',
                                  height: 55,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 統計數據區塊
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50, // 修改為棕色調
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
              // _buildInfoListTile(Icons.person, '使用者名稱', username),
              _buildInfoListTile(Icons.email, '電子郵件', email),
              _buildBirthdayListTile(Icons.cake, '生日', formattedBirthday),
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

              // const SizedBox(height: 16),

              // 學習統計卡片
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/widget_pic/post_it.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 25.0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 39),
                      // 連續學習天數
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.red[900],
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
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
                          Icon(
                            Icons.calendar_view_week,
                            color: Colors.blue[900],
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
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
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[900],
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
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
                    backgroundColor: Colors.brown.shade600, // 修改為棕色
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
      ),
    );
  }

  // 構建統計數據列
  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.brown.shade600, size: 24), // 修改為棕色
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
          Icon(icon, color: Colors.brown.shade600), // 修改為棕色
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

  // 修改生日相關的 ListTile，添加編輯功能
  Widget _buildBirthdayListTile(IconData icon, String title, String value) {
    bool canEdit = (userData?['birthday'] ?? '').isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade600), // 修改為棕色
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
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.brown.shade600), // 修改為棕色
              onPressed: () => _editBirthday(context),
              tooltip: '設定生日',
            ),
        ],
      ),
    );
  }
}
