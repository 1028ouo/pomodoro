import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/models/task.dart';
import 'package:pomodoro/models/task_list.dart';
import 'package:pomodoro/services/task_service.dart';

class TaskListDetailPage extends StatefulWidget {
  final TaskList taskList;

  const TaskListDetailPage({Key? key, required this.taskList}) : super(key: key);

  @override
  State<TaskListDetailPage> createState() => _TaskListDetailPageState();
}

class _TaskListDetailPageState extends State<TaskListDetailPage> {
  final TextEditingController _taskController = TextEditingController();
  final TaskService _taskService = TaskService();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // 選擇日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: '選擇截止日期',
      cancelText: '取消',
      confirmText: '確定',
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                onSurface: Theme.of(context).colorScheme.secondary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 新增任務
  void _addTask() {
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
                '新增待辦事項',
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
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: '輸入待辦事項...',
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
                  InkWell(
                    onTap: () async {
                      await _selectDate(context);
                      setDialogState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '截止日期',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            _selectedDate == null
                                ? '選擇日期'
                                : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: _selectedDate == null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _taskController.clear();
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_taskController.text.isNotEmpty) {
                      Task newTask = Task(
                        title: _taskController.text,
                        dueDate: _selectedDate,
                        listId: widget.taskList.id,
                        createdAt: DateTime.now(),
                      );
                      await _taskService.addTask(newTask);
                      Navigator.pop(context);
                      _taskController.clear();
                      setState(() {
                        _selectedDate = null;
                      });
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

  // 格式化日期
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 獲取對應圖標
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getIconData(widget.taskList.icon), size: 24),
            const SizedBox(width: 12),
            Text(widget.taskList.name),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            color: const Color.fromARGB(255, 247, 233, 220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '刪除列表',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('刪除列表'),
                    content: Text(
                      '確定要刪除"${widget.taskList.name}"列表及其所有任務嗎？此操作無法復原。',
                    ),
                    backgroundColor: const Color.fromARGB(255, 251, 232, 214),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _taskService.deleteTaskList(widget.taskList.id!);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('刪除'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_pic/list_detail.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<List<Task>>(
          stream: _taskService.getTasksByList(widget.taskList.id!),
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
                      Icons.assignment_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '尚無待辦事項',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '新增一個待辦事項開始規劃你的一天',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            List<Task> tasks = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Dismissible(
                      key: Key(task.id ?? ''),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        if (task.id != null) {
                          _taskService.deleteTask(task.id!, widget.taskList.id!);
                        }
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: task.dueDate != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(task.dueDate),
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        leading: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => _taskService.toggleTaskCompletion(task),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: Theme.of(context).colorScheme.secondary,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
