import 'package:flutter/material.dart';
import 'package:designdynamos/ui/widgets/custom_calendar.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/ui/widgets/large_box.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Fetch tasks after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().refreshAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Replace this with your real TaskProvider fetch
    final tasks = context.watch<TaskProvider>().allTasks;

    // Filter tasks for selected day
    final tasksForSelectedDay = tasks.where((task) {
      final dueLocal = task.dueAt?.toLocal();
      if (dueLocal == null) return false; // ignore tasks with no due date
       final dueDate = DateTime(dueLocal.year, dueLocal.month, dueLocal.day);
       final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

        // Show task if it's due on the selected day
        return dueDate == selectedDate;
    }).toList()
      ..sort((a, b) => a.orderHint.compareTo(b.orderHint));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              "Calendar",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(),
                  height: 850,
                  width: 900,
                  child: CustomCalendar(
                    onDaySelectedCallback: (selectedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 40), // spacing between calendar and box
                Container(
                  margin: const EdgeInsets.only(top: 100), // adjust top margin
                  height: 675,
                  width: 500,
                  child: LargeBox(
                    label: 'Tasks',
                    child: tasksForSelectedDay.isEmpty
                        ? const Center(
                            child: Text(
                              "No tasks for this day",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView(
                            children: tasksForSelectedDay
                                .map(
                                  (task) => TaskCard(
                                    task: task,
                                    onTap: () {},
                                    onToggle: null,
                                    subtaskDone: context
                                        .read<TaskProvider>()
                                        .subtaskProgress(task.id)
                                        .$1,
                                    subtaskTotal: context
                                        .read<TaskProvider>()
                                        .subtaskProgress(task.id)
                                        .$2,
                                    labels: context
                                        .read<TaskProvider>()
                                        .labelsOf(task.id),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
