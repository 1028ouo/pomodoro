import 'package:flutter/material.dart';
import 'dart:async';
import '../services/food_service.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart'; // 新增 UserService 引用

// 定義冒險獎勵(料理)資料結構
class FoodReward {
  final String name;
  final String emoji;
  final String description;

  FoodReward({
    required this.name,
    required this.emoji,
    required this.description,
  });
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 番茄鐘狀態
  bool isRunning = false;
  bool isBreak = false;
  int remainingSeconds = 25 * 60; // 25分鐘專注時間
  Timer? timer;

  // 服務
  final FoodService _foodService = FoodService();
  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();

  // 原始專注時間（秒）
  final int focusTimeSeconds = 25 * 60; // 專注時間
  final int breakTimeSeconds = 5 * 60; // 休息時間

  // 獎勵相關
  List<FoodReward> earnedRewards = [];
  bool isLoadingRecipe = false;

  // // 假資料：可能獲得的獎勵
  // final List<FoodReward> possibleRewards = [
  //   FoodReward(name: '營火烤肉', emoji: '🍖', description: '在營火上烤製的美味肉類'),
  //   FoodReward(name: '野炊湯品', emoji: '🍲', description: '用山泉水熬煮的鮮美湯品'),
  //   FoodReward(name: '烤馬鈴薯', emoji: '🥔', description: '煨在炭火中的香甜馬鈴薯'),
  //   FoodReward(name: '野莓果醬', emoji: '🍓', description: '用野外採集的漿果製作的果醬'),
  //   FoodReward(name: '露營咖啡', emoji: '☕', description: '在戶外煮的香醇咖啡'),
  //   FoodReward(name: '森林三明治', emoji: '🥪', description: '用野菜製作的健康三明治'),
  // ];

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    if (mounted) {
      setState(() {
        isRunning = true;
        // 測試用短時間
        remainingSeconds = isBreak ? 5 : 5;
        // 正式環境設定
        // remainingSeconds = isBreak ? breakTimeSeconds : focusTimeSeconds;
      });
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        if (!isBreak) {
          // 專注時間結束，開始休息
          if (mounted) {
            setState(() {
              isBreak = true;
            });
          }
          startTimer(); // 開始休息時間
        } else {
          // 休息時間結束，獲得食譜獎勵
          getRandomRecipeReward();
          if (mounted) {
            setState(() {
              isRunning = false;
              isBreak = false;
            });
          }
        }
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        isRunning = false;
      });
    }
  }

  // 獲取並儲存隨機食譜
  Future<void> getRandomRecipeReward() async {
    setState(() {
      isLoadingRecipe = true;
    });

    try {
      // 如果完成的是專注時間（而非休息時間），則更新用戶統計資料
      if (!isBreak) {
        // 更新使用者的番茄鐘統計資料（使用實際完成的專注時間）
        await _userService.updatePomodoroStats(focusTimeSeconds);
      }

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

  // void earnReward() {
  //   // 隨機選擇一個獎勵
  //   final reward =
  //       possibleRewards[DateTime.now().millisecondsSinceEpoch %
  //           possibleRewards.length];
  //   if (mounted) {
  //     setState(() {
  //       earnedRewards.add(reward);
  //     });
  //     // 顯示獲得獎勵的提示
  //     showDialog(
  //       context: context,
  //       builder:
  //           (context) => AlertDialog(
  //             title: Center(child: const Text('You got this！')),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(reward.emoji, style: const TextStyle(fontSize: 50)),
  //                 const SizedBox(height: 10),
  //                 Text(
  //                   reward.name,
  //                   style: const TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 5),
  //                 Text(reward.description),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('太棒了！'),
  //               ),
  //             ],
  //           ),
  //     );
  //   }
  // }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 80),
          const SizedBox(height: 20),
          Text(
            isBreak ? '休息時間' : '專注時間',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            formatTime(remainingSeconds),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isRunning ? null : startTimer,
                child: const Text('開始專注'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: isRunning ? stopTimer : null,
                child: const Text('停止'),
              ),
            ],
          ),
          if (isLoadingRecipe)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
