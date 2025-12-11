import 'package:flutter/material.dart';
import 'package:designdynamos/ui/widgets/custom_calendar.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/ui/widgets/large_box.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/providers/tts_provider.dart';
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  bool _announced = false;
  int _lastTaskCount = -1;

  @override
  void initState() {
    super.initState();

    //Fetch tasks after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().refreshAllTasks();
    });
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;

    final tts = context.read<TtsProvider>();
    if (tts.isEnabled) {
      _announced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tts.speak('Calendar screen');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Replace this with your real TaskProvider fetch
    final tasks = context.watch<TaskProvider>().allTasks;

    //Build event counts by due date (local day)
    final Map<DateTime, int> eventCounts = {};
    for (final task in tasks) {
      final dueLocal = task.dueAt?.toLocal();
      if (dueLocal == null) continue;
      final key = DateTime(dueLocal.year, dueLocal.month, dueLocal.day);
      eventCounts[key] = (eventCounts[key] ?? 0) + 1;
    }

    //Filter tasks for selected day
    final tasksForSelectedDay = tasks.where((task) {
      final dueLocal = task.dueAt?.toLocal();
      if (dueLocal == null) return false; //ignore tasks with no due date
       final dueDate = DateTime(dueLocal.year, dueLocal.month, dueLocal.day);
       final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

        //Show task if it's due on the selected day
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
            Semantics(
              header: true,
              label: "Calendar Screen",
              child: Text(
                "Calendar(Shows Tasks due on that day)",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
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
                    eventCounts: eventCounts,
                    onDaySelectedCallback: (selectedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                      });
                      
                      // Announce task count when day is selected
                      final ttsProvider = context.read<TtsProvider>();
                      final tasksForDay = tasks.where((task) {
                        final dueLocal = task.dueAt?.toLocal();
                        if (dueLocal == null) return false;
                        final dueDate = DateTime(dueLocal.year, dueLocal.month, dueLocal.day);
                        final selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                        return dueDate == selectedDate;
                      }).length;
                      
                      if (ttsProvider.isEnabled && tasksForDay != _lastTaskCount) {
                        _lastTaskCount = tasksForDay;
                        final monthName = _getMonthName(selectedDay.month);
                        final announcement = tasksForDay == 0
                            ? 'No tasks for $monthName ${selectedDay.day}'
                            : '$tasksForDay ${tasksForDay == 1 ? "task" : "tasks"} found for $monthName ${selectedDay.day}';
                        ttsProvider.speak(announcement);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 40), //spacing between calendar and box
                Container(
                  margin: const EdgeInsets.only(top: 100), //adjust top margin
                  height: 675,
                  width: 500,
                  child: LargeBox(
                    label: 'Tasks',
                    child: Semantics(
                      label: tasksForSelectedDay.isEmpty 
                          ? 'No tasks for selected day' 
                          : '${tasksForSelectedDay.length} ${tasksForSelectedDay.length == 1 ? "task" : "tasks"} for selected day',
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
