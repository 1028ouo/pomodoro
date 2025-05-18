import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pomodoro/models/task.dart';
import 'package:pomodoro/models/task_list.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取當前用戶ID
  String? get _userId => _auth.currentUser?.uid;

  // 用戶任務列表集合路徑
  String _userListsCollection(String userId) => 'users/$userId/lists';

  // 用戶任務集合路徑 - 修改為列表子集合
  String _userTasksCollection(String userId, String listId) =>
      'users/$userId/lists/$listId/tasks';

  // 獲取任務列表流
  Stream<List<TaskList>> getTaskLists() {
    final userId = _userId;
    if (userId == null) {
      // 用戶未登入，返回空列表
      return Stream.value([]);
    }

    return _firestore
        .collection(_userListsCollection(userId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskList.fromFirestore(doc)).toList(),
        );
  }

  // 新增任務列表
  Future<DocumentReference> addTaskList(TaskList taskList) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('用戶未登入');
    }

    return await _firestore
        .collection(_userListsCollection(userId))
        .add(taskList.toFirestore());
  }

  // 刪除任務列表
  Future<void> deleteTaskList(String listId) async {
    final userId = _userId;
    if (userId == null) return;

    // 開始一個批次處理
    WriteBatch batch = _firestore.batch();

    // 刪除任務列表
    DocumentReference listRef = _firestore
        .collection(_userListsCollection(userId))
        .doc(listId);
    batch.delete(listRef);

    // 獲取並刪除該列表下的所有任務
    QuerySnapshot tasksSnapshot =
        await _firestore.collection(_userTasksCollection(userId, listId)).get();

    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 提交批次
    await batch.commit();
  }

  // 獲取特定列表下的任務流
  Stream<List<Task>> getTasksByList(String listId) {
    final userId = _userId;
    if (userId == null) {
      // 用戶未登入，返回空列表
      return Stream.value([]);
    }

    return _firestore
        .collection(_userTasksCollection(userId, listId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // 獲取所有任務流 (需調整實現方式)
  Stream<List<Task>> getTasks() {
    final userId = _userId;
    if (userId == null) {
      // 用戶未登入，返回空列表
      return Stream.value([]);
    }

    // 先獲取所有列表
    return _firestore
        .collection(_userListsCollection(userId))
        .snapshots()
        .asyncMap((listSnapshots) async {
          List<Task> allTasks = [];

          // 對每個列表獲取其任務
          for (var listDoc in listSnapshots.docs) {
            String listId = listDoc.id;

            QuerySnapshot taskSnapshot =
                await _firestore
                    .collection(_userTasksCollection(userId, listId))
                    .orderBy('createdAt', descending: true)
                    .get();

            List<Task> listTasks =
                taskSnapshot.docs
                    .map((doc) => Task.fromFirestore(doc))
                    .toList();

            allTasks.addAll(listTasks);
          }

          // 按創建時間排序
          allTasks.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );

          return allTasks;
        });
  }

  // 新增任務
  Future<void> addTask(Task task) async {
    final userId = _userId;
    if (userId == null || task.listId == null) return;

    // 添加創建時間戳記
    final taskData = task.toFirestore();
    taskData['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(_userTasksCollection(userId, task.listId!))
        .add(taskData);
  }

  // 切換任務完成狀態
  Future<void> toggleTaskCompletion(Task task) async {
    final userId = _userId;
    if (userId == null || task.id == null || task.listId == null) return;

    await _firestore
        .collection(_userTasksCollection(userId, task.listId!))
        .doc(task.id)
        .update({'isCompleted': !task.isCompleted});
  }

  // 刪除任務
  Future<void> deleteTask(String taskId, String listId) async {
    final userId = _userId;
    if (userId == null) return;

    await _firestore
        .collection(_userTasksCollection(userId, listId))
        .doc(taskId)
        .delete();
  }
}
