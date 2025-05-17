import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取當前用戶的ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 獲取用戶文檔引用
  DocumentReference? get userRef =>
      currentUserId != null
          ? _firestore.collection('users').doc(currentUserId)
          : null;

  // 完成一個番茄鐘時更新統計資料
  Future<void> updatePomodoroStats(int focusTimeSeconds) async {
    if (currentUserId == null) return;

    // 獲取目前的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();

    // 獲取當前週的起始日期 (以週一為起點)
    final weekStart =
        DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        ).toIso8601String();

    // 獲取用戶目前的數據
    final userDoc = await userRef!.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    // 檢查是否需要更新連續學習天數
    final lastActiveDate = userData['lastActiveDate'] ?? '';
    int streakDays = userData['streakDays'] ?? 0;

    // 計算連續學習天數
    if (lastActiveDate != today) {
      // 如果今天是第一次活動
      final yesterday =
          DateTime(now.year, now.month, now.day - 1).toIso8601String();

      if (lastActiveDate == yesterday) {
        // 如果昨天有活動，增加連續天數
        streakDays++;
      } else if (lastActiveDate != '') {
        // 如果中間有間斷，重置連續天數
        streakDays = 1;
      } else {
        // 如果是首次記錄
        streakDays = 1;
      }
    }

    // 更新本週學習時間
    final String lastWeekStart = userData['currentWeekStart'] ?? '';
    int weeklyFocusTime = userData['weeklyFocusTime'] ?? 0;

    // 如果是新的一週，重置週計數
    if (lastWeekStart != weekStart) {
      weeklyFocusTime = focusTimeSeconds;
    } else {
      weeklyFocusTime += focusTimeSeconds;
    }

    // 更新總專注時間和完成的番茄鐘數量
    final int totalFocusTime =
        (userData['totalFocusTime'] ?? 0) + focusTimeSeconds;
    final int completedPomodoros = (userData['completedPomodoros'] ?? 0) + 1;

    // 批次更新所有統計數據
    await userRef!.update({
      'lastActiveDate': today,
      'streakDays': streakDays,
      'currentWeekStart': weekStart,
      'weeklyFocusTime': weeklyFocusTime,
      'totalFocusTime': totalFocusTime,
      'completedPomodoros': completedPomodoros,
    });
  }

  // 獲取用戶的所有統計數據
  Future<Map<String, dynamic>> getUserStats() async {
    if (currentUserId == null) return {};

    final userDoc = await userRef!.get();
    return userDoc.data() as Map<String, dynamic>? ?? {};
  }
}
