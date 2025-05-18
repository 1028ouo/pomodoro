import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? createdAt;
  final String? listId; // 新增: 關聯的任務列表 ID

  Task({
    this.id,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    this.createdAt,
    this.listId, // 新增: 關聯的任務列表 ID
  });

  // 從 Firestore 轉換為 Task 物件
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      listId: data['listId'], // 新增: 關聯的任務列表 ID
    );
  }

  // 轉換為可存儲到 Firestore 的 Map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(), // 添加創建時間，如果沒有則使用服務器時間
      'listId': listId, // 關聯的任務列表 ID
    };
  }
}
