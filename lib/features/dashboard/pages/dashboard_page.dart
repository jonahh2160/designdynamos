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
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/task_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

//state
class _DashboardPageState extends State<DashboardPage> {
  var selectedIndex = 0;
  bool isSidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    final mainDest = DashboardConstants.mainDestinations;
    final secondaryDest = DashboardConstants.secondaryDestinations;
    final mainDestLength = mainDest.length;
    final secondaryDestLength = secondaryDest.length;
    final incompleteToday = context
        .select<TaskProvider, int>((p) => p.today.where((t) => !t.isDone).length);

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
        final bool isCompact = constraints.maxWidth < 1100;
        final bool showLabels = !isCompact && isSidebarOpen;

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: showLabels ? 240 : 88,
                  decoration: BoxDecoration(
                    color: AppColors.sidebar,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: showLabels
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: showLabels
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: IconButton(
                          icon: Icon(
                            isSidebarOpen
                                ? Icons.arrow_back_ios
                                : Icons.arrow_forward_ios,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              isSidebarOpen = !isSidebarOpen;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: showLabels ? 24 : 0,
                        ),
                        child: showLabels
                            ? Text(
                                'Tasqly',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                              )
                            : SizedBox.shrink(), //Icon(
                            //     Icons.add_task,
                            //     size: 32,
                            //     color: AppColors.textMuted,
                            //   ),
                      ),
                      SizedBox(height: showLabels ? 32 : 24),
                      //Primary nav items
                      ...List.generate(mainDestLength, (index) {
                        final item = mainDest[index];
                        final isActive = selectedIndex == index;
                        final badge = (index == 0 && incompleteToday > 0)
                            ? incompleteToday.toString()
                            : item.badge;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => selectedIndex = index);
                            if (index == 0) {
                              //When navigating back to Daily Tasks, refresh from server
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  context
                                      .read<TaskProvider>()
                                      .refreshToday()
                                      .catchError(
                                        (error) => debugPrint(
                                          'refreshToday failed: $error',
                                        ),
                                      );
                                }
                              });
                            }
                          },
                          child: SidebarButton(
                            item: NavItemData(
                              item.icon,
                              item.label,
                              badge: badge,
                              isActive: isActive,
                            ),
                            showLabel: showLabels,
                          ),
                        );
                      }),
                      const Spacer(),
                      //Secondary nav items
                      ...List.generate(secondaryDestLength, (i) {
                        final index = i + mainDestLength;
                        final item = secondaryDest[i];
                        final isActive = selectedIndex == index;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
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
                            showLabel: showLabels,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  //Use the app's scaffold background to avoid the greenish tint
                  color: Theme.of(context).scaffoldBackgroundColor,
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
