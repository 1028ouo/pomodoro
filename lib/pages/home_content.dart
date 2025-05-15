import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
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
    );
  }
}
