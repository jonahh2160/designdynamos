import 'package:flutter/material.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:designdynamos/core/models/task_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/features/daily_tasks/widgets/overdue_task_alert.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

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
            Text(
              "All Tasks",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: tasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => taskProvider.selectTask(task.id),
                            onToggle: () async {
                              await taskProvider.toggleDone(task.id, !task.isDone);
                            },
                            isSelected: taskProvider.selectedTask?.id == task.id,
                            subtaskDone: taskProvider.subtaskProgress(task.id).$1,
                            subtaskTotal: taskProvider.subtaskProgress(task.id).$2,
                            labels: taskProvider.labelsOf(task.id),
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