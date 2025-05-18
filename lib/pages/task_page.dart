import 'package:flutter/material.dart';
import 'package:pomodoro/models/task.dart'; // 添加這個 import
import 'package:pomodoro/models/task_list.dart';
import 'package:pomodoro/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pomodoro/pages/task_list_detail_page.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _listNameController = TextEditingController();
  final TaskService _taskService = TaskService();
  String _selectedIcon = 'list'; // 預設圖標
  bool _isLoading = false;

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  // 可選圖標列表
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': '列表', 'value': 'list'},
    {'name': '工作', 'value': 'work'},
    {'name': '學習', 'value': 'school'},
    {'name': '健康', 'value': 'fitness_center'},
    {'name': '購物', 'value': 'shopping_cart'},
    {'name': '家庭', 'value': 'home'},
    {'name': '旅行', 'value': 'flight'},
    {'name': '娛樂', 'value': 'movie'},
  ];

  // 根據圖標名稱取得 Icon 物件
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'movie':
        return Icons.movie;
      case 'list':
      default:
        return Icons.list;
    }
  }

  void _addTaskList() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                '新增任務列表',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _listNameController,
                    decoration: InputDecoration(
                      hintText: '輸入列表名稱...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '選擇圖標',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        _availableIcons.map((icon) {
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                _selectedIcon = icon['value'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    _selectedIcon == icon['value']
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.2)
                                        : Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      _selectedIcon == icon['value']
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _getIconData(icon['value']),
                                    color:
                                        _selectedIcon == icon['value']
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(context).iconTheme.color,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    icon['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _selectedIcon == icon['value']
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                              : Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _listNameController.clear();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_listNameController.text.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        TaskList newList = TaskList(
                          name: _listNameController.text,
                          icon: _selectedIcon,
                          createdAt: DateTime.now(),
                        );

                        final docRef = await _taskService.addTaskList(newList);
                        Navigator.pop(context);

                        // 清空表單
                        _listNameController.clear();
                        _selectedIcon = 'list';
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('新增列表失敗: ${e.toString()}')),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('新增'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 檢查用戶是否登入
    final isUserLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (!isUserLoggedIn) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                '請先登入',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '登入後即可查看並管理你的待辦事項',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 這裡可以導航到登入頁面
                  // Navigator.of(context).pushNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('前往登入'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的任務列表'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              )
              : StreamBuilder<List<TaskList>>(
                stream: _taskService.getTaskLists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '尚無任務列表',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '建立一個列表開始安排你的任務',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  List<TaskList> taskLists = snapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                      itemCount: taskLists.length,
                      itemBuilder: (context, index) {
                        final taskList = taskLists[index];
                        return InkWell(
                          onTap: () {
                            // 導航到任務列表詳情頁
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TaskListDetailPage(taskList: taskList),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIconData(taskList.icon),
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  taskList.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<List<Task>>(
                                  stream: _taskService.getTasksByList(
                                    taskList.id!,
                                  ),
                                  builder: (context, taskSnapshot) {
                                    int taskCount = 0;
                                    if (taskSnapshot.hasData) {
                                      taskCount = taskSnapshot.data!.length;
                                    }
                                    return Text(
                                      '$taskCount 個任務',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTaskList,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        tooltip: '新增任務列表',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
