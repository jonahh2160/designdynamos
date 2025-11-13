import "package:flutter/material.dart";
import 'package:intl/intl.dart';

import 'package:designdynamos/ui/widgets/large_box.dart';

class OutlookScreen extends StatelessWidget {
  const OutlookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    //generate a list of 14 days starting from today
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

            //Title
            Text(
              "Outlook",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 40),

            //Scrollable boxes section
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
                      final formattedDate = DateFormat(
                        'EEEE, MMM d',
                      ).format(day); //e.g. "Monday, Oct 21"

                      //Use your reusable widget here
                      return LargeBox(
                        label: formattedDate,
                        child: const Text(
                          "Events go here",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
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
