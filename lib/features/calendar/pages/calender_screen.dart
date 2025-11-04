import 'package:flutter/material.dart';
import 'package:designdynamos/ui/widgets/custom_calendar.dart';
import 'package:designdynamos/core/theme/app_colors.dart';



class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 900, //makes it a clean centered panel
          child: CustomCalendar(),
        ),
      ),
    );
  }
}