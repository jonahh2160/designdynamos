import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/core/models/nav_item_data.dart';
import 'package:designdynamos/features/achievements/pages/achievements_screen.dart';
import 'package:designdynamos/features/auth/pages/signout_screen.dart';
import 'package:designdynamos/features/calendar/pages/calender_screen.dart';
import 'package:designdynamos/features/dashboard/utils/dashboard_constants.dart';
import 'package:designdynamos/features/dashboard/widgets/sidebar_button.dart';
import 'package:designdynamos/features/games/pages/games_screen.dart';
import 'package:designdynamos/features/goals/pages/goals_screen.dart';
import 'package:designdynamos/features/outlook/pages/outlook_screen.dart';
import 'package:designdynamos/features/popout/pages/popout_screen.dart';
import 'package:designdynamos/features/settings/pages/settings_screen.dart';
import 'package:designdynamos/features/tasks/pages/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:designdynamos/features/daily_tasks/pages/daily_task_screen.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

//state
class _DashboardPageState extends State<DashboardPage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final mainDest = DashboardConstants.mainDestinations;
    final secondaryDest = DashboardConstants.secondaryDestinations;
    final mainDestLength = mainDest.length;
    final secondaryDestLength = secondaryDest.length;

    
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = DailyTaskScreen();
        break;
      case 1:
        page = CalendarScreen();
        break;
      case 2:
        page = OutlookScreen();
        break;
      case 3:
        page = TasksScreen();
        break;
      case 4:
        page = GoalsScreen();
        break;
      case 5:
        page = AchievementsScreen();
        break;
      case 6:
        page = GamesScreen();
        break;
      case 7:
        page = PopOutScreen();
        break;
      case 8:
        page = SettingsScreen();
        break;
      case 9:
        page = SignOutScreen();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: AppColors.sidebar,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Tasqly',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      //Primary nav items
                      ...List.generate(mainDestLength, (
                        index,
                      ) {
                        final item = mainDest[index];
                        final isActive = selectedIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedIndex = index);
                          },
                          child: SidebarButton(
                            item: NavItemData(
                              item.icon,
                              item.label,
                              badge: item.badge,
                              isActive: isActive,
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Secondary nav items
                      ...List.generate(
                        secondaryDestLength,
                        (i) {
                          final index =
                              i + mainDestLength;
                          final item = secondaryDest[i];
                          final isActive = selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedIndex = index);
                            },
                            child: SidebarButton(
                              item: NavItemData(
                                item.icon,
                                item.label,
                                isActive: isActive,
                              ),
                              isSecondary: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}