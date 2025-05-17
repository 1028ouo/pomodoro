import 'package:flutter/material.dart';
import 'dart:async';

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

  // 獎勵相關
  List<FoodReward> earnedRewards = [];

  // 假資料：可能獲得的獎勵
  final List<FoodReward> possibleRewards = [
    FoodReward(name: '營火烤肉', emoji: '🍖', description: '在營火上烤製的美味肉類'),
    FoodReward(name: '野炊湯品', emoji: '🍲', description: '用山泉水熬煮的鮮美湯品'),
    FoodReward(name: '烤馬鈴薯', emoji: '🥔', description: '煨在炭火中的香甜馬鈴薯'),
    FoodReward(name: '野莓果醬', emoji: '🍓', description: '用野外採集的漿果製作的果醬'),
    FoodReward(name: '露營咖啡', emoji: '☕', description: '在戶外煮的香醇咖啡'),
    FoodReward(name: '森林三明治', emoji: '🥪', description: '用野菜製作的健康三明治'),
  ];

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    if (mounted) {
      setState(() {
        isRunning = true;
        remainingSeconds = isBreak ? 5 : 5;
      });
    }

    // 實際應用中這裡會是25分鐘，為了測試設定較短時間
    // 在實際產品中改回正常時間
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
          // 休息時間結束，完成一個循環，獲得獎勵
          earnReward();
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

  void earnReward() {
    // 隨機選擇一個獎勵
    final reward =
        possibleRewards[DateTime.now().millisecondsSinceEpoch %
            possibleRewards.length];
    if (mounted) {
      setState(() {
        earnedRewards.add(reward);
      });

      // 顯示獲得獎勵的提示
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Center(child: const Text('You got this！')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reward.emoji, style: const TextStyle(fontSize: 50)),
                  const SizedBox(height: 10),
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(reward.description),
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
  }

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
        ],
      ),
    );
  }
}
