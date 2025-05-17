import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String title;
  bool isCompleted;
  DateTime? dueDate;

  Task({this.id, required this.title, this.isCompleted = false, this.dueDate});

  // 從 Firestore 轉換為 Task 物件
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      dueDate:
          data['dueDate'] != null
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
    );
  }

  // 轉換為可存儲到 Firestore 的 Map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }
}
