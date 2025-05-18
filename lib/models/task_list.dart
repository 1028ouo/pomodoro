import 'package:cloud_firestore/cloud_firestore.dart';

class TaskList {
  final String? id;
  final String name;
  final String icon;
  final DateTime? createdAt;

  TaskList({this.id, required this.name, required this.icon, this.createdAt});

  // 從 Firestore 轉換為 TaskList 物件
  factory TaskList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TaskList(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'list',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // 轉換為可存儲到 Firestore 的 Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
