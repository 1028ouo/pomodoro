import 'package:flutter/material.dart';
import 'dart:async';
import '../services/food_service.dart';
import '../services/recipe_service.dart';
import '../services/user_service.dart';
import '../services/timer_manager.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  final TimerManager timerManager = TimerManager();
  Timer? _timer;

  // 背景圖片狀態
  String backgroundImage = 'assets/background_pic/home_morn.png';
  String _previousBackgroundImage = 'assets/background_pic/home_morn.png';

  // 控制器和動畫
  late AnimationController _backgroundController;
  late Animation<double> _backgroundFadeAnimation;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // 服務
  final FoodService _foodService = FoodService();
  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();

  bool isLoadingRecipe = false;

  @override
  void initState() {
    super.initState();

    // 初始化按鈕動畫控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 縮放動畫
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 透明度動畫
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // 初始化背景轉場動畫控制器
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 背景淡入淡出動畫
    _backgroundFadeAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  @override
  void dispose() {
    // 確保在元件銷毀時取消計時器和動畫控制器
    _timer?.cancel();
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void startTimer() {
    if (mounted) {
      setState(() {
        timerManager.start();

        // 設定初始專注背景
        if (!timerManager.isBreak) {
          _changeBackground('assets/background_pic/focus_1.png');
        }
      });
    }

    // 啟動按鈕動畫效果
    _animationController.forward().then((_) => _animationController.reverse());

    // 取消已存在的計時器
    _timer?.cancel();

    // 創建新的計時器並保存引用
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!timerManager.isCompleted()) {
        if (mounted) {
          setState(() {
            timerManager.decrementTime();

            // 根據剩餘時間更新背景圖片（僅在專注模式下）
            if (!timerManager.isBreak) {
              updateBackgroundBasedOnTime();
            }
          });
        }
      } else {
        timer.cancel();
        if (!timerManager.isBreak) {
          // 專注時間結束，記錄統計資料
          _updateUserStats();

          // 開始休息
          if (mounted) {
            setState(() {
              timerManager.switchToBreak();
              // 設定休息時的背景圖片
              _changeBackground('assets/background_pic/home_night.png');
            });
          }
          startTimer(); // 開始休息時間
        } else {
          // 休息時間結束，獲得食譜獎勵
          getRandomRecipeReward();
          if (mounted) {
            setState(() {
              timerManager.reset();
              _changeBackground('assets/background_pic/home_morn.png');
            });
          }
        }
      }
    });
  }

  Future<void> _updateUserStats() async {
    try {
      await _userService.updatePomodoroStats(timerManager.focusTimeSeconds);
    } catch (e) {
      print('更新番茄鐘統計資料失敗: $e');
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _animationController.forward().then((_) => _animationController.reverse());

    if (mounted) {
      setState(() {
        timerManager.stop();
        _changeBackground('assets/background_pic/home_morn.png');
      });
    }
  }

  // 更新背景圖片
  void updateBackgroundBasedOnTime() {
    int totalTime = timerManager.getCurrentTotalTime();
    int elapsedTime = timerManager.getElapsedTime();
    String newBackground;

    if (elapsedTime < totalTime * 2 / 5) {
      newBackground = 'assets/background_pic/focus_1.png';
    } else if (elapsedTime < totalTime * 3 / 5) {
      newBackground = 'assets/background_pic/focus_2.png';
    } else {
      newBackground = 'assets/background_pic/focus_3.png';
    }

    // 檢查背景是否需要更新
    if (backgroundImage != newBackground) {
      _changeBackground(newBackground);
    }
  }

  // 背景切換動畫
  void _changeBackground(String newBackground) {
    if (backgroundImage == newBackground) return;

    // 保存當前背景作為前一個背景
    _previousBackgroundImage = backgroundImage;

    // 更新新背景
    backgroundImage = newBackground;

    // 重置並開始背景轉場動畫
    _backgroundController.reset();
    _backgroundController.forward();
  }

  // 獲取並儲存隨機食譜
  Future<void> getRandomRecipeReward() async {
    setState(() {
      isLoadingRecipe = true;
    });

    try {
      // 獲取隨機食譜
      final recipe = await _foodService.getRandomRecipe();

      // 檢查是否已經獲得過這個食譜
      final hasRecipe = await _firebaseService.hasRecipe(recipe.id);

      // 保存到Firestore
      await _firebaseService.saveRecipe(recipe.id, recipe.title, recipe.image);

      // 顯示獲得的食譜
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Center(child: Text(hasRecipe ? '再次獲得食譜！' : '獲得新食譜！')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        recipe.image,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (ctx, error, stackTrace) =>
                                const Icon(Icons.restaurant, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recipe.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasRecipe)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          '(你已經擁有這個食譜)',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('太棒了！'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('獲取食譜失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRecipe = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景轉場效果
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Stack(
              children: [
                // 舊背景（淡出）
                Positioned.fill(
                  child: Opacity(
                    opacity: 1.0 - _backgroundFadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_previousBackgroundImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                // 新背景（淡入）
                Positioned.fill(
                  child: Opacity(
                    opacity: _backgroundFadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(backgroundImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 100),

              // 番茄鐘卡片
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform:
                        Matrix4.identity()
                          ..scale(timerManager.isRunning ? 1.02 : 1.0),
                    child: AspectRatio(
                      aspectRatio: 5 / 3,
                      child: Stack(
                        children: [
                          // 背景圖片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Hero(
                              tag: 'timer_card',
                              child: Image.asset(
                                'assets/widget_pic/focus_time.png',
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),

                          // 內容
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 15.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 控制按鈕
                                Padding(
                                  padding: const EdgeInsets.only(left: 35.0),
                                  child: Material(
                                    elevation: 4,
                                    shape: const CircleBorder(),
                                    color: Colors.transparent,
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _scaleAnimation.value,
                                          child: AnimatedOpacity(
                                            opacity: _opacityAnimation.value,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (timerManager.isRunning) {
                                                  stopTimer();
                                                } else {
                                                  startTimer();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                shape: const CircleBorder(),
                                                backgroundColor:
                                                    timerManager.isRunning
                                                        ? Colors.brown
                                                            .withOpacity(0.9)
                                                        : Colors.red.shade900
                                                            .withOpacity(0.9),
                                              ),
                                              child: Icon(
                                                timerManager.isRunning
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 42,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // 時間顯示
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 24.0,
                                    top: 15,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0.0, 0.5),
                                                  end: Offset.zero,
                                                ).animate(animation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            timerManager.isBreak
                                                ? '休息時間'
                                                : '專注時間',
                                            key: ValueKey<bool>(
                                              timerManager.isBreak,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Text(
                                                timerManager.formatTime(),
                                                style: const TextStyle(
                                                  fontSize: 37,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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
              ),

              // Loading indicator
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child:
                      isLoadingRecipe
                          ? const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: CircularProgressIndicator(),
                          )
                          : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
