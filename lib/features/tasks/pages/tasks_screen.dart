import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:designdynamos/providers/task_provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _announced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;

    final tts = context.read<TtsProvider>();
    if (tts.isEnabled) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tts.speak('All Tasks screen');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.allTasks;

    if (taskProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Semantics(
              header: true,
              label: 'All Tasks Screen',
              child: Text(
                "All Tasks",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: tasks.isEmpty
                    ? Center(
                        child: Semantics(
                          label: 'No tasks available',
                          child: const Text(
                            'No tasks available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Semantics(
                            label: task.title,
                            child: TaskCard(
                              task: task,
                              onTap: () => taskProvider.selectTask(task.id),
                              onToggle: () async {
                                await taskProvider.toggleDone(task.id, !task.isDone);
                              },
                              isSelected: taskProvider.selectedTask?.id == task.id,
                              subtaskDone: taskProvider.subtaskProgress(task.id).$1,
                              subtaskTotal: taskProvider.subtaskProgress(task.id).$2,
                              labels: taskProvider.labelsOf(task.id),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
