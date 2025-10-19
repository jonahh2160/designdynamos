import "package:flutter/material.dart";
import 'package:designdynamos/ui/screen/dashboard/dashboad_controller.dart';
import 'package:designdynamos/ui/widgets/card_announce_medium.dart';
import 'package:designdynamos/ui/widgets/headline.dart';
import 'package:designdynamos/ui/widgets/navigate_button.dart';
import 'package:designdynamos/ui/widgets/card_with_transparent_border.dart';
import 'package:designdynamos/ui/widgets/subtitle.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class OutlookScreen extends StatelessWidget {
  const OutlookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    // generate a list of 14 days starting from today
    final DateTime today = DateTime.now();
    final List<DateTime> days =
        List.generate(14, (index) => today.add(Duration(days: index)));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // Top title text
            Text(
              "Outlook",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30
                  ),
            ),
            const SizedBox(height: 40),
            
            
            Center( // ⬅️ vertically centers inside that space// Scrollable boxes
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
                      final formattedDate = DateFormat('EEEE, MMM d').format(day); // Example: "Monday, Oct 21"

                      return Container(
                        width: 500,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.subtaskBackground,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.textMuted ?? Colors.grey,
                            width: 1.5
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              color: Colors.white70,
                              thickness: 1,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Events go here",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
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