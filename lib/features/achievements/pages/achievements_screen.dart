import 'package:flutter/material.dart';
import 'package:designdynamos/ui/widgets/large_box.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            //Main title
            Text(
              "Achievements",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
            ),

            const SizedBox(height: 40),

            //Row of boxes
            SizedBox(
              height: 700,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  LargeBox(
                    label: "Coin Leaderboard",
                    child: Text(
                      "Leaderboard Coming Soon",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  LargeBox(
                    label: "Your Badges",
                    child: Text(
                      "Badges Coming Soon",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Streaks",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
        ),
                ],
              
              ),
            ),

            
    ]
  ),
    )
    );
  }
}

