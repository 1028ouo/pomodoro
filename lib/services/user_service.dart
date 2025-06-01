import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 用戶服務類 - 處理用戶相關的資料操作
class UserService {
  // Firebase 服務實例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取當前用戶的 ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 獲取用戶文檔引用 - 用於訪問用戶的 Firestore 數據
  DocumentReference? get userRef =>
      currentUserId != null
          ? _firestore.collection('users').doc(currentUserId)
          : null;

  // 完成一個番茄鐘時更新用戶統計資料
  Future<void> updatePomodoroStats(int focusTimeSeconds) async {
    // 確認用戶已登入
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

    // 從 Firestore 獲取用戶目前的數據
    final userDoc = await userRef!.get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    // 計算連續學習天數邏輯
    final lastActiveDate = userData['lastActiveDate'] ?? '';
    int streakDays = userData['streakDays'] ?? 0;

    if (lastActiveDate != today) {
      // 今天是第一次活動
      final yesterday =
          DateTime(now.year, now.month, now.day - 1).toIso8601String();

      if (lastActiveDate == yesterday) {
        // 昨天有活動，增加連續天數
        streakDays++;
      } else if (lastActiveDate != '') {
        // 中間有間斷，重置連續天數
        streakDays = 1;
      } else {
        // 首次記錄活動
        streakDays = 1;
      }
    }

    // 計算本週學習時間
    final String lastWeekStart = userData['currentWeekStart'] ?? '';
    int weeklyFocusTime = userData['weeklyFocusTime'] ?? 0;

    // 如果是新的一週，重置週計數
    if (lastWeekStart != weekStart) {
      weeklyFocusTime = focusTimeSeconds;
    } else {
      // 在當前週內，累加學習時間
      weeklyFocusTime += focusTimeSeconds;
    }

    // 更新總專注時間和完成的番茄鐘數量
    final int totalFocusTime =
        (userData['totalFocusTime'] ?? 0) + focusTimeSeconds;
    final int completedPomodoros = (userData['completedPomodoros'] ?? 0) + 1;

    // 批次更新所有統計數據到 Firestore
    await userRef!.update({
      'lastActiveDate': today, // 最後活動日期
      'streakDays': streakDays, // 連續學習天數
      'currentWeekStart': weekStart, // 本週開始日期
      'weeklyFocusTime': weeklyFocusTime, // 本週學習時間(秒)
      'totalFocusTime': totalFocusTime, // 總學習時間(秒)
      'completedPomodoros': completedPomodoros, // 已完成的番茄鐘數量
    });
  }

  // 獲取用戶的所有統計數據
  Future<Map<String, dynamic>> getUserStats() async {
    // 確認用戶已登入
    if (currentUserId == null) return {};

    // 從 Firestore 獲取完整的用戶文檔
    final userDoc = await userRef!.get();
    return userDoc.data() as Map<String, dynamic>? ?? {};
  }
}
