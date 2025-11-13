import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:designdynamos/core/theme/app_colors.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      width: 450,
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
        rowHeight: 85,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },

        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          headerPadding: EdgeInsets.only(bottom: 16),
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
}
