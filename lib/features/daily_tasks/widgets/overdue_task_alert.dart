import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:designdynamos/core/models/task_item.dart';

typedef OverdueTaskAction = Future<void> Function(TaskItem task);

class OverdueTaskAlert extends StatelessWidget {
  final TaskItem task;
  final OverdueTaskAction onDelete;
  final OverdueTaskAction onComplete;
  final OverdueTaskAction onMoveDate;

  const OverdueTaskAlert({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onComplete,
    required this.onMoveDate,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = DateFormat.yMMMd().format(task.dueAt!);
    return Card(
      color: const Color.fromARGB(255, 243, 152, 15),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task "${task.title}" was due on $dueDate but was not marked completed.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await onDelete(task);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  },
                  child: const Text('Delete Task'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await onComplete(task);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task marked complete')),
                    );
                  },
                  child: const Text('Mark Complete'),
                ),
                ElevatedButton(
                  onPressed: () => onMoveDate(task),
                  child: const Text('Move Task Date'),
                ),
              ],
            )
          ),
          ],
        ),
      ),
    );
  }
}
