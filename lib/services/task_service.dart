import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pomodoro/models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // 獲取任務流
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // 新增任務
  Future<void> addTask(Task task) async {
    await _firestore.collection(_collection).add(task.toFirestore());
  }

  // 切換任務完成狀態
  Future<void> toggleTaskCompletion(Task task) async {
    if (task.id != null) {
      await _firestore.collection(_collection).doc(task.id).update({
        'isCompleted': !task.isCompleted,
      });
    }
  }

  // 刪除任務
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).delete();
  }
}
