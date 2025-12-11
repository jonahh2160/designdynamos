import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';

import 'package:designdynamos/ui/widgets/large_box.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:provider/provider.dart';


class OutlookScreen extends StatefulWidget {
  const OutlookScreen({super.key});

  @override
  State<OutlookScreen> createState() => _OutlookScreenState();
}

class _OutlookScreenState extends State<OutlookScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    //Fetch tasks after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().refreshAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().allTasks;

    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(
      14,
      (index) => today.add(Duration(days: index)),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              "Outlook",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                height: 700,
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView.separated(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final formattedDate =
                          DateFormat('EEEE, MMM d').format(day);
                      final DateTime dayStart = DateTime(day.year, day.month, day.day);
                      final DateTime dayEnd = dayStart.add(const Duration(days: 1));

                      final tasksForDay = tasks.where((t) {
                        if (t.isDone) return false;
                        final startLocal = t.startDate?.toLocal() ?? t.dueAt?.toLocal();
                        final start = startLocal != null
                            ? DateTime(startLocal.year, startLocal.month, startLocal.day)
                            : null;
                        if (start == null) return false;
                        final dueLocal = t.dueAt?.toLocal() ?? startLocal;
                        final due = dueLocal != null
                            ? DateTime(dueLocal.year, dueLocal.month, dueLocal.day)
                            : start;

                        final startsBeforeOrOnDay = !start.isAfter(dayEnd.subtract(const Duration(milliseconds: 1)));
                        final dueOnOrAfterDay = !due.isBefore(dayStart);

                        //Show every day from start through due (inclusive) while not completed.
                        return startsBeforeOrOnDay && dueOnOrAfterDay;
                      }).toList()
                        ..sort((a, b) => a.orderHint.compareTo(b.orderHint));
                      return LargeBox(
                        label: formattedDate,
                        child: SizedBox(
                          height: 575, //or any height that fits your layout
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView(
                            children: tasksForDay.isEmpty
                              ? [const Text("No events", style: TextStyle(color: Colors.white70))]
                              : tasksForDay.map((task) => TaskCard(
                                task: task,
                                onTap: () {},
                                onToggle: null,
                                subtaskDone: context.read<TaskProvider>().subtaskProgress(task.id).$1,
                                subtaskTotal: context.read<TaskProvider>().subtaskProgress(task.id).$2,
                                labels: context.read<TaskProvider>().labelsOf(task.id),
                              )).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
