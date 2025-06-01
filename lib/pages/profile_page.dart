import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

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

    // 兔子動畫 (旋轉角度)
    _rabbitSwingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.8, end: -0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: -0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.6, end: -0.5), weight: 30),
    ]).animate(_animationController);

    // 貓咪動畫 (旋轉角度)
    _catSwingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.5), weight: 30),
    ]).animate(_animationController);

    // 兔子位置
    _rabbitPositionAnimation = Tween<double>(begin: -100, end: -20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // 貓咪位置
    _catPositionAnimation = Tween<double>(begin: -100, end: -32).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // 頁面載入後開始播放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // 釋放動畫資源
    super.dispose();
  }

  // 從 Firestore 獲取用戶資料
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
          // 如果用戶資料存在，載入資料
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
          });
        } else {
          // 用戶不存在，創建用戶
          int randomPicId = 1 + (DateTime.now().millisecondsSinceEpoch % 10);
          String profilePicId = 'pic_$randomPicId';

          // 設定用戶資料
          Map<String, dynamic> newUserData = {
            'username': currentUser.displayName ?? '使用者',
            'email': currentUser.email ?? '',
            'joinedAt': DateTime.now().toIso8601String(),
            'totalFocusTime': 0,
            'streakDays': 0,
            'weeklyFocusTime': 0,
            'completedPomodoros': 0,
            'birthday': '',
            'profilePicId': profilePicId,
          };

          // 儲存新用戶資料
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

  // 登出
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 顯示確認對話框
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

      // 取消登出
      if (shouldLogout != true) {
        return;
      }

      // 顯示登出
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登出中...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 執行登出
      await FirebaseAuth.instance.signOut();

      // 登出後回登入
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登出時發生錯誤: $e')));
      }
    }
  }

  // 處理生日編輯
  Future<void> _editBirthday(BuildContext context) async {
    // 檢查生日是否已設定
    String currentBirthday = userData?['birthday'] ?? '';
    if (currentBirthday.isNotEmpty) {
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
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

    // 用戶選擇了日期
    if (pickedDate != null) {
      String formattedDate = pickedDate.toIso8601String();

      // 透過 AuthService 更新生日資料
      final result = await _authService.updateBirthday(formattedDate);

      if (context.mounted) {
        if (result['success']) {
          // 更新成功
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
    // 顯示載入中畫面
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 如果沒有用戶資料或未登入，顯示提示訊息
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

    // 獲取並格式化用戶資料
    String username = userData!['username'] ?? '未知用戶';
    String email = _auth.currentUser?.email ?? '未設定郵箱';
    String joinedAt = userData!['joinedAt'] ?? '';
    String birthday = userData!['birthday'] ?? '';
    int totalFocusTime = userData!['totalFocusTime'] ?? 0;
    int streakDays = userData!['streakDays'] ?? 0;
    int weeklyFocusTime = userData!['weeklyFocusTime'] ?? 0;
    int completedPomodoros = userData!['completedPomodoros'] ?? 0;
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

    // 將秒數轉換為時分格式
    int hours = totalFocusTime ~/ 3600;
    int minutes = (totalFocusTime % 3600) ~/ 60;
    String formattedFocusTime = '$hours 小時 $minutes 分鐘';

    // 將本週學習時間轉換為時分格式
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 用戶頭像
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.brown.shade100,
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/profile_pic/$profilePicId.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // 兔子動畫
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
                        // 貓咪動畫
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
                    // 用戶名稱
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

              // 上面的統計卡片
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
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

              // 個人資訊標題
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '個人資訊',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // 個人資訊項目
              _buildInfoListTile(Icons.email, '電子郵件', email),
              _buildBirthdayListTile(Icons.cake, '生日', formattedBirthday),
              _buildInfoListTile(
                Icons.event_available,
                '加入日期',
                formattedJoinedDate,
              ),

              const Divider(),

              // 學習統計標題
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '學習統計',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

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
                      const SizedBox(height: 39),
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

              // 登出按鈕
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
                    backgroundColor: Colors.brown.shade600,
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

  // 建立統計數據
  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.brown.shade600, size: 24),
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

  // 建立一般資訊
  Widget _buildInfoListTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade600),
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

  // 建立生日資訊列表項 (編輯功能)
  Widget _buildBirthdayListTile(IconData icon, String title, String value) {
    bool canEdit = (userData?['birthday'] ?? '').isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade600),
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
          // 只有未設定生日時才顯示編輯按鈕
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.brown.shade600),
              onPressed: () => _editBirthday(context),
              tooltip: '設定生日',
            ),
        ],
      ),
    );
  }
}
