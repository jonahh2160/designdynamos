import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:provider/provider.dart';

class CustomCalendar extends StatefulWidget {
  final void Function(DateTime selectedDay)? onDaySelectedCallback;
  final Map<DateTime, int> eventCounts;

  const CustomCalendar({
    super.key,
    this.onDaySelectedCallback,
    this.eventCounts = const {},
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _initialAnnouncementMade = false;

  @override
  void initState() {
    super.initState();
    // Initialize with today's date
    _selectedDay = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Announce the initial highlighted day on first load
    if (!_initialAnnouncementMade && _selectedDay != null) {
      _initialAnnouncementMade = true;
      final ttsProvider = context.read<TtsProvider>();
      if (ttsProvider.isEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _announceDay(_selectedDay!);
        });
      }
    }
  }

  void _announceDay(DateTime day) {
    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isEnabled) return;

    final key = DateTime(day.year, day.month, day.day);
    final count = widget.eventCounts[key] ?? 0;
    final monthName = _getMonthName(day.month);
    final isToday = isSameDay(day, DateTime.now());
    
    String announcement = 'Calendar date ${monthName} ${day.day}, ${day.year}';
    if (isToday) {
      announcement += ', today';
    }
    if (count > 0) {
      announcement += ', $count ${count == 1 ? "task" : "tasks"}';
    }
    
    ttsProvider.speak(announcement);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.subtaskBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 2)),
        ],
        border: Border.all(color: AppColors.textMuted, width: 1.5),
      ),
      child: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        rowHeight: 111,
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          final count = widget.eventCounts[key] ?? 0;
          return List.generate(count, (_) => 'event');
        },
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          
          // Announce selected date and task count via TTS
          final ttsProvider = context.read<TtsProvider>();
          if (ttsProvider.isEnabled) {
            final key = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            final count = widget.eventCounts[key] ?? 0;
            final announcement = count == 0
                ? 'Date ${selectedDay.day}, no tasks'
                : 'Date ${selectedDay.day}, $count ${count == 1 ? "task" : "tasks"}';
            ttsProvider.speak(announcement);
          }
          
          if (widget.onDaySelectedCallback != null) {
            widget.onDaySelectedCallback!(selectedDay);
          }
        },

        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          headerPadding: const EdgeInsets.only(bottom: 16),
          
          leftChevronIcon: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              final ttsProvider = context.read<TtsProvider>();
              if (ttsProvider.isEnabled) {
                ttsProvider.speak('Previous month button');
              }
            },
            child: Semantics(
              label: 'Previous month button',
              button: true,
              enabled: true,
              child: Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
          rightChevronIcon: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              final ttsProvider = context.read<TtsProvider>();
              if (ttsProvider.isEnabled) {
                ttsProvider.speak('Next month button');
              }
            },
            child: Semantics(
              label: 'Next month button',
              button: true,
              enabled: true,
              child: Icon(Icons.chevron_right, color: AppColors.textPrimary),
            ),
          ),
        ),
        
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) {
            return Semantics(
              label: '${_getMonthName(day.month)} ${day.year}. Use previous month button on the left and next month button on the right to navigate.',
              child: Text(
                '${_getMonthName(day.month)} ${day.year}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final count = events.length;
            return Align(
              alignment: Alignment.bottomRight,
              child: Semantics(
                label: '$count ${count == 1 ? "task" : "tasks"}',
                child: Container(
                  margin: const EdgeInsets.only(right: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.taskCardHighlight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textPrimary),
          weekendStyle: TextStyle(color: AppColors.textPrimary),
        ),

        calendarStyle: CalendarStyle(
          tablePadding: const EdgeInsets.only(top: 15),
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
          cellPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),

          defaultDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: AppColors.subtaskBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textSecondary, width: 1),
          ),

          weekendDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: AppColors.subtaskBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textSecondary, width: 1),
          ),
          todayDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: (AppColors.taskCardHighlight).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          selectedDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: AppColors.taskCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          cellAlignment: Alignment.topLeft,
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
