import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import 'package:designdynamos/features/daily_tasks/widgets/task_card.dart';
import 'package:designdynamos/providers/task_provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:designdynamos/ui/widgets/large_box.dart';


class OutlookScreen extends StatefulWidget {
  const OutlookScreen({super.key});

  @override
  State<OutlookScreen> createState() => _OutlookScreenState();
}

class _OutlookScreenState extends State<OutlookScreen> {
  final ScrollController scrollController = ScrollController();
  bool _announced = false;
  DateTime? _lastScrollAnnounce;

  void _announceScrollbar(TtsProvider tts) {
    if (!tts.isEnabled) return;

    final now = DateTime.now();
    if (_lastScrollAnnounce != null &&
        now.difference(_lastScrollAnnounce!) < const Duration(seconds: 2)) {
      return;
    }

    _lastScrollAnnounce = now;
    tts.speak(
      'Horizontal scrollbar. Use mouse wheel, trackpad, or arrow keys to move between days.',
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!scrollController.hasClients) return;

    // Map vertical wheel movement to horizontal scroll; preserve any native horizontal delta.
    final delta = event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    if (delta == 0) return;

    final position = scrollController.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    scrollController.jumpTo(target);
  }

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
    // Announce page title once when TTS is enabled
    if (!_announced) {
      final tts = context.read<TtsProvider>();
      if (tts.isEnabled) {
        _announced = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) tts.speak('Outlook screen');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().allTasks;
    final tts = context.read<TtsProvider>();

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
            Semantics(
              header: true,
              label: "Outlook Screen",
              child: Text(
                "Outlook",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
              ),
            ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                height: 700,
                child: Semantics(
                  label: 'Day list with horizontal scrollbar. Use mouse wheel, trackpad, or arrow keys to navigate days.',
                  hint: 'Scrollable horizontally',
                  child: MouseRegion(
                    opaque: true,
                    onEnter: (_) => _announceScrollbar(tts),
                    onHover: (_) => _announceScrollbar(tts),
                    child: Listener(
                      onPointerSignal: _handlePointerSignal,
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
                        ),
                      );
                    },
                  ),
                ),
                ),
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
