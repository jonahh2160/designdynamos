import 'package:flutter/material.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/core/widgets/action_chip_button.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    //Warming the cache on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskProvider>().refreshAllTasks();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.allTasks;
    final filtered = _query.isEmpty
        ? tasks
        : tasks.where((task) {
            final title = task.title.toLowerCase();
            final notes = (task.notes ?? '').toLowerCase();
            final q = _query.toLowerCase();
            return title.contains(q) || notes.contains(q);
          }).toList();

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
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or notes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _searchController.clear(),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No tasks available'
                              : 'No tasks match "${_query}"',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TaskCard(
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
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ActionChipButton(
                                  icon: Icons.today_outlined,
                                  label: 'Set due today',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final due = task.dueAt?.toLocal();
                                    final today = DateUtils.dateOnly(DateTime.now());
                                    if (due != null && DateUtils.isSameDay(due, today)) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Task is already due today'),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await taskProvider.setDueToday(task.id);
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Due date set to today')),
                                      );
                                    } catch (error) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to update due date: $error')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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
