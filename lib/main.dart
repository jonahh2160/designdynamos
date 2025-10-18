import 'package:flutter/material.dart';


void main() {
 runApp(const MyApp());
}


class MyApp extends StatelessWidget {
 const MyApp({super.key});


 @override
 Widget build(BuildContext context) {
   return MaterialApp(
     debugShowCheckedModeBanner: false,
     title: 'Tasqly',
     theme: ThemeData(
       brightness: Brightness.dark,
       scaffoldBackgroundColor: AppColors.background,
       colorScheme: const ColorScheme.dark(
         primary: AppColors.taskCard,
         secondary: AppColors.accent,
       ),
       
       textTheme: Theme.of(context).textTheme.apply(
         bodyColor: AppColors.textPrimary,
         displayColor: AppColors.textPrimary,
       ),
     ),
     home: const DashboardPage(),
   );
 }
}


class DashboardPage extends StatefulWidget {
 const DashboardPage({super.key});


 static const List<NavItemData> _mainDestinations = [
   NavItemData(Icons.home, 'Daily Tasks', badge: '3', isActive: true),
   NavItemData(Icons.event_note, 'Calendar'),
   NavItemData(Icons.vrpano, 'Outlook'),
   NavItemData(Icons.view_list, 'All Tasks'),
   NavItemData(Icons.flag, 'Goals'),
   NavItemData(Icons.emoji_events, 'Achievements'),
   NavItemData(Icons.sports_esports, 'Games'),
 ];


 static const List<NavItemData> _secondaryDestinations = [
   NavItemData(Icons.open_in_new, 'Pop out'),
   NavItemData(Icons.settings, 'Settings'),
   NavItemData(Icons.logout, 'Sign Out'),
 ];


  //need to pull from database
 static const List<TaskItem> _todayTasks = [
   TaskItem(
     title: 'Make Bed',
     icon: Icons.bed,
     score: 9,
     progress: 0.5,
     progressLabel: '1/2',
     metadata: [
       TagInfo(label: 'Due Today', icon: Icons.calendar_today_outlined),
       TagInfo(label: 'Self Care', icon: Icons.self_improvement_outlined),
     ],
   ),
   TaskItem(
     title: 'Drink Water',
     icon: Icons.local_drink,
     score: 6,
     metadata: [TagInfo(label: 'Self Care', icon: Icons.water_drop_outlined)],
   ),
   TaskItem(
     title: 'Eat Breakfast',
     icon: Icons.restaurant,
     score: 7,
     metadata: [TagInfo(label: 'Health', icon: Icons.favorite_outline)],
   ),
 ];


 static const List<TaskItem> _completedTasks = [
   TaskItem(title: 'Do something', icon: Icons.check, completed: true),
   TaskItem(title: 'Do something', icon: Icons.check, completed: true),
   TaskItem(title: 'Do something', icon: Icons.check, completed: true),
 ];


 static const List<SubtaskItem> _makeBedSubtasks = [
   SubtaskItem(title: 'Wash bedding', completed: true),
   SubtaskItem(title: 'Dry bedding'),
 ];

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

//state
class _DashboardPageState extends State<DashboardPage> {

 var selectedIndex = 0;
 @override
 Widget build(BuildContext context) {

  Widget page;

  switch(selectedIndex){
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
    builder: (context, constraints){
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(icon: Icon(Icons.home), label: Text('Daily Tasks')),
                  NavigationRailDestination(icon: Icon(Icons.event_note), label: Text('Calendar')),
                  NavigationRailDestination(icon: Icon(Icons.vrpano), label: Text('Outlook')),
                  NavigationRailDestination(icon: Icon(Icons.view_list), label: Text('All Tasks')),
                  NavigationRailDestination(icon: Icon(Icons.flag), label: Text('Goals')),
                  NavigationRailDestination(icon: Icon(Icons.emoji_events), label: Text('Achievements')),
                  NavigationRailDestination(icon: Icon(Icons.sports_esports), label: Text('Games')),
                  NavigationRailDestination(icon: Icon(Icons.open_in_new), label: Text('Pop out')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                  NavigationRailDestination(icon: Icon(Icons.logout), label: Text('Sign Out')),
                  

                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,

                ),

              ),
          ]
        ),
      );
    }
    
    
    );
  
 }
}

class DailyTaskScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body: SafeArea(
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Row(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             SizedBox(
               width: 240,
               child: Sidebar(
                 title: 'Daily Tasks (Pane open)',
                 primaryItems: DashboardPage._mainDestinations,
                 secondaryItems: DashboardPage._secondaryDestinations,
               ),
             ),
             const SizedBox(width: 24),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const ProgressOverview(
                     completed: 8,
                     total: 11,
                     coins: 600,
                     streakLabel: '8/11 tasks completed',
                   ),
                   const SizedBox(height: 24),
                   Row(
                     children: [
                       Expanded(
                         child: Text(
                           'October 4',
                           style: Theme.of(context).textTheme.headlineSmall
                               ?.copyWith(
                                 fontWeight: FontWeight.w600,
                                 color: AppColors.textPrimary,
                               ),
                         ),
                       ),
                       const ActionChipButton(
                         icon: Icons.auto_awesome,
                         label: 'Suggestions',
                       ),
                       const SizedBox(width: 12),
                       const ActionChipButton(
                         icon: Icons.filter_list,
                         label: 'Filter',
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   Expanded(
                     child: SingleChildScrollView(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           for (final task in DashboardPage._todayTasks)
                             TaskCard(task: task),
                           const SizedBox(height: 16),
                           const FinishedSectionHeader(title: 'Finished - 8'),
                           const SizedBox(height: 12),
                           for (final task in DashboardPage._completedTasks)
                             TaskCard(task: task),
                           const SizedBox(height: 16),
                           const AddTaskCard(),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ),
             const SizedBox(width: 24),
             const SizedBox(
               width: 300,
               child: TaskDetailPanel(
                 title: 'Make Bed',
                 score: 9,
                 subtasks: DashboardPage._makeBedSubtasks,
                 tags: [
                   TagInfo(label: 'Due Oct. 4', icon: Icons.event_available),
                   TagInfo(label: 'Goals', icon: Icons.flag_outlined),
                   TagInfo(
                     label: 'Self Care',
                     icon: Icons.local_florist_outlined,
                   ),
                   TagInfo(
                     label: 'Priority 9',
                     icon: Icons.priority_high_outlined,
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
     ),
   );
  }
}

class Sidebar extends StatelessWidget {
 const Sidebar({
   super.key,
   required this.title,
   required this.primaryItems,
   required this.secondaryItems,
 });


 final String title;
 final List<NavItemData> primaryItems;
 final List<NavItemData> secondaryItems;


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.sidebar,
       borderRadius: BorderRadius.circular(24),
     ),
     padding: const EdgeInsets.symmetric(vertical: 24),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24),
           child: Text(
             title,
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               fontWeight: FontWeight.w600,
               color: AppColors.textMuted,
             ),
           ),
         ),
         const SizedBox(height: 32),
         ...primaryItems.map((item) => SidebarButton(item: item)),
         const Spacer(),
         ...secondaryItems.map(
           (item) => SidebarButton(item: item, isSecondary: true),
         ),
       ],
     ),
   );
 }
}


class SidebarButton extends StatelessWidget {
 const SidebarButton({
   super.key,
   required this.item,
   this.isSecondary = false,
 });


 final NavItemData item;
 final bool isSecondary;


 @override
 Widget build(BuildContext context) {
   final bool active = item.isActive && !isSecondary;
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
     child: Container(
       decoration: BoxDecoration(
         color: active ? AppColors.sidebarActive : Colors.transparent,
         borderRadius: BorderRadius.circular(16),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       child: Row(
         children: [
           Icon(
             item.icon,
             size: 22,
             color: active
                 ? AppColors.textPrimary
                 : AppColors.textSecondary.withOpacity(
                     isSecondary ? 0.6 : 0.8,
                   ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Text(
               item.label,
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: active
                     ? AppColors.textPrimary
                     : AppColors.textSecondary.withOpacity(
                         isSecondary ? 0.7 : 0.85,
                       ),
                 fontWeight: active ? FontWeight.w600 : FontWeight.w500,
               ),
             ),
           ),
           if (item.badge != null)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: AppColors.accent,
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 item.badge!,
                 style: const TextStyle(
                   color: Colors.black87,
                   fontWeight: FontWeight.w600,
                   fontSize: 12,
                 ),
               ),
             ),
         ],
       ),
     ),
   );
 }
}


class ProgressOverview extends StatelessWidget {
 const ProgressOverview({
   super.key,
   required this.completed,
   required this.total,
   required this.coins,
   required this.streakLabel,
 });


 final int completed;
 final int total;
 final int coins;
 final String streakLabel;


 @override
 Widget build(BuildContext context) {
   final double progress = total == 0 ? 0 : completed / total;
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
     decoration: BoxDecoration(
       color: AppColors.surface,
       borderRadius: BorderRadius.circular(24),
     ),
     child: Row(
       children: [
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: SizedBox(
                   height: 18,
                   child: Stack(
                     children: [
                       Container(
                         decoration: const BoxDecoration(
                           color: AppColors.progressTrack,
                         ),
                       ),
                       FractionallySizedBox(
                         widthFactor: progress.clamp(0, 1),
                         child: Container(
                           decoration: BoxDecoration(
                             gradient: const LinearGradient(
                               colors: [
                                 AppColors.taskCard,
                                 AppColors.taskCardHighlight,
                               ],
                             ),
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 streakLabel,
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   color: AppColors.textSecondary,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ],
           ),
         ),
         const SizedBox(width: 24),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
           decoration: BoxDecoration(
             color: AppColors.sidebarActive,
             borderRadius: BorderRadius.circular(16),
           ),
           child: Row(
             children: [
               Icon(Icons.monetization_on, color: AppColors.accent),
               const SizedBox(width: 8),
               Text(
                 coins.toString(),
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.w600,
                   color: AppColors.textPrimary,
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }
}


class FinishedSectionHeader extends StatelessWidget {
 const FinishedSectionHeader({super.key, required this.title});


 final String title;


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.finishedBadge,
       borderRadius: BorderRadius.circular(20),
     ),
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         const Icon(Icons.expand_more, color: AppColors.textPrimary, size: 20),
         const SizedBox(width: 8),
         Text(
           title,
           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
             fontWeight: FontWeight.w600,
             color: AppColors.textPrimary,
           ),
         ),
       ],
     ),
   );
 }
}


class TaskCard extends StatelessWidget {
 const TaskCard({super.key, required this.task});


 final TaskItem task;


 @override
 Widget build(BuildContext context) {
   final bool completed = task.completed;
   final Color backgroundColor = completed
       ? AppColors.completedCard
       : AppColors.taskCard;
   final Color textColor = completed
       ? AppColors.textPrimary.withOpacity(0.7)
       : AppColors.textPrimary;
   final TextStyle titleStyle =
       Theme.of(context).textTheme.titleMedium?.copyWith(
         fontWeight: FontWeight.w600,
         color: textColor,
         decoration: completed
             ? TextDecoration.lineThrough
             : TextDecoration.none,
         decorationColor: textColor.withOpacity(0.8),
       ) ??
       TextStyle(
         color: textColor,
         fontWeight: FontWeight.w600,
         decoration: completed
             ? TextDecoration.lineThrough
             : TextDecoration.none,
       );


   return Padding(
     padding: const EdgeInsets.symmetric(vertical: 8),
     child: Container(
       decoration: BoxDecoration(
         color: backgroundColor,
         borderRadius: BorderRadius.circular(22),
         border: completed
             ? Border.all(color: AppColors.completedBorder, width: 1.4)
             : null,
       ),
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.center,
         children: [
           _StatusPip(isCompleted: completed),
           const SizedBox(width: 14),
           IconContainer(icon: task.icon, isCompleted: completed),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(task.title, style: titleStyle),
                 if (!completed &&
                     (task.progress != null || task.metadata.isNotEmpty))
                   const SizedBox(height: 10),
                 if (!completed && task.progress != null)
                   Row(
                     children: [
                       SizedBox(
                         width: 90,
                         height: 6,
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(4),
                           child: LinearProgressIndicator(
                             value: task.progress!.clamp(0, 1),
                             backgroundColor: AppColors.progressTrack
                                 .withOpacity(0.6),
                             valueColor: const AlwaysStoppedAnimation<Color>(
                               AppColors.taskCardHighlight,
                             ),
                           ),
                         ),
                       ),
                       if (task.progressLabel != null) ...[
                         const SizedBox(width: 8),
                         Text(
                           task.progressLabel!,
                           style: Theme.of(context).textTheme.labelSmall
                               ?.copyWith(
                                 color: AppColors.textPrimary,
                                 fontWeight: FontWeight.w600,
                               ),
                         ),
                       ],
                     ],
                   ),
                 if (!completed && task.metadata.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   Wrap(
                     spacing: 10,
                     runSpacing: 6,
                     children: task.metadata
                         .map((tag) => TagChip(tag: tag))
                         .toList(),
                   ),
                 ],
               ],
             ),
           ),
           if (!completed && task.score != null)
             Container(
               padding: const EdgeInsets.symmetric(
                 horizontal: 12,
                 vertical: 10,
               ),
               decoration: BoxDecoration(
                 color: AppColors.scoreBadge.withOpacity(0.5),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Text(
                 '${task.score}',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                   color: AppColors.textPrimary,
                   fontWeight: FontWeight.w700,
                 ),
               ),
             ),
         ],
       ),
     ),
   );
 }
}


class AddTaskCard extends StatelessWidget {
 const AddTaskCard({super.key});


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.taskCard,
       borderRadius: BorderRadius.circular(22),
     ),
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
     child: Row(
       children: [
         Container(
           height: 36,
           width: 36,
           decoration: BoxDecoration(
             color: AppColors.sidebarActive,
             borderRadius: BorderRadius.circular(12),
           ),
           child: const Icon(Icons.add, color: AppColors.textPrimary),
         ),
         const SizedBox(width: 16),
         Expanded(
           child: Text(
             'Add task',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               color: AppColors.textPrimary,
               fontWeight: FontWeight.w600,
             ),
           ),
         ),
         const Icon(
           Icons.calendar_today_outlined,
           color: AppColors.textPrimary,
           size: 22,
         ),
         const SizedBox(width: 12),
         const Icon(
           Icons.flag_outlined,
           color: AppColors.textPrimary,
           size: 22,
         ),
         const SizedBox(width: 12),
         const Icon(
           Icons.local_offer_outlined,
           color: AppColors.textPrimary,
           size: 22,
         ),
       ],
     ),
   );
 }
}


class TaskDetailPanel extends StatelessWidget {
 const TaskDetailPanel({
   super.key,
   required this.title,
   required this.score,
   required this.subtasks,
   required this.tags,
 });


 final String title;
 final int score;
 final List<SubtaskItem> subtasks;
 final List<TagInfo> tags;


 @override
 Widget build(BuildContext context) {
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       TaskSummaryCard(title: title, score: score, subtasks: subtasks),
       const SizedBox(height: 16),
       InfoCard(tags: tags),
       const SizedBox(height: 16),
       const NotesCard(),
     ],
   );
 }
}


class TaskSummaryCard extends StatelessWidget {
 const TaskSummaryCard({
   super.key,
   required this.title,
   required this.score,
   required this.subtasks,
 });


 final String title;
 final int score;
 final List<SubtaskItem> subtasks;


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.detailCard,
       borderRadius: BorderRadius.circular(24),
     ),
     padding: const EdgeInsets.all(20),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           children: [
             const _StatusPip(isCompleted: false),
             const SizedBox(width: 16),
             IconContainer(icon: Icons.bed, isCompleted: false),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     title,
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.w700,
                     ),
                   ),
                   const SizedBox(height: 6),
                   Row(
                     children: [
                       const Icon(
                         Icons.star,
                         size: 18,
                         color: AppColors.accent,
                       ),
                       const SizedBox(width: 6),
                       Text(
                         'Priority $score',
                         style: Theme.of(context).textTheme.bodySmall
                             ?.copyWith(color: AppColors.textSecondary),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
             IconButton(
               onPressed: () {},
               icon: const Icon(
                 Icons.delete_outline,
                 color: AppColors.textSecondary,
               ),
             ),
           ],
         ),
         const SizedBox(height: 16),
         for (final subtask in subtasks) ...[
           SubtaskRow(subtask: subtask),
           const SizedBox(height: 12),
         ],
         TextButton.icon(
           onPressed: () {},
           icon: const Icon(
             Icons.add,
             color: AppColors.textSecondary,
             size: 18,
           ),
           label: Text(
             'Add subtask',
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
               color: AppColors.textSecondary,
               fontWeight: FontWeight.w600,
             ),
           ),
         ),
       ],
     ),
   );
 }
}


class InfoCard extends StatelessWidget {
 const InfoCard({super.key, required this.tags});


 final List<TagInfo> tags;


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.detailCard,
       borderRadius: BorderRadius.circular(24),
     ),
     padding: const EdgeInsets.all(20),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         for (final tag in tags) ...[
           Row(
             children: [
               Icon(
                 tag.icon ?? Icons.tag_outlined,
                 color: AppColors.textSecondary,
                 size: 20,
               ),
               const SizedBox(width: 12),
               Text(
                 tag.label,
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   color: AppColors.textPrimary,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ],
           ),
           if (tag != tags.last) const SizedBox(height: 12),
         ],
       ],
     ),
   );
 }
}


class NotesCard extends StatelessWidget {
 const NotesCard({super.key});


 @override
 Widget build(BuildContext context) {
   return Expanded(
     child: Container(
       decoration: BoxDecoration(
         color: AppColors.detailCard,
         borderRadius: BorderRadius.circular(24),
       ),
       padding: const EdgeInsets.all(20),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Notes',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               fontWeight: FontWeight.w600,
               color: AppColors.textPrimary,
             ),
           ),
           const SizedBox(height: 12),
           Text(
             'Add notes',
             style: Theme.of(
               context,
             ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
           ),
         ],
       ),
     ),
   );
 }
}


class SubtaskRow extends StatelessWidget {
 const SubtaskRow({super.key, required this.subtask});


 final SubtaskItem subtask;


 @override
 Widget build(BuildContext context) {
   final bool completed = subtask.completed;
   return Container(
     decoration: BoxDecoration(
       color: AppColors.subtaskBackground,
       borderRadius: BorderRadius.circular(16),
     ),
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
     child: Row(
       children: [
         Icon(
           completed
               ? Icons.check_circle
               : Icons.radio_button_unchecked_outlined,
           color: completed ? AppColors.accent : AppColors.textSecondary,
           size: 20,
         ),
         const SizedBox(width: 12),
         Expanded(
           child: Text(
             subtask.title,
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
               color: completed
                   ? AppColors.textSecondary
                   : AppColors.textPrimary,
               decoration: completed
                   ? TextDecoration.lineThrough
                   : TextDecoration.none,
             ),
           ),
         ),
         IconButton(
           onPressed: () {},
           icon: const Icon(
             Icons.delete_outline,
             size: 20,
             color: AppColors.textSecondary,
           ),
         ),
       ],
     ),
   );
 }
}


class IconContainer extends StatelessWidget {
 const IconContainer({
   super.key,
   required this.icon,
   required this.isCompleted,
 });


 final IconData icon;
 final bool isCompleted;


 @override
 Widget build(BuildContext context) {
   return Container(
     height: 40,
     width: 40,
     decoration: BoxDecoration(
       color: isCompleted
           ? AppColors.sidebarActive.withOpacity(0.6)
           : AppColors.sidebarActive,
       borderRadius: BorderRadius.circular(12),
     ),
     child: Icon(icon, color: AppColors.textPrimary),
   );
 }
}


class _StatusPip extends StatelessWidget {
 const _StatusPip({required this.isCompleted});


 final bool isCompleted;


 @override
 Widget build(BuildContext context) {
   return Container(
     height: 24,
     width: 24,
     decoration: BoxDecoration(
       shape: BoxShape.circle,
       color: isCompleted ? AppColors.accent : Colors.transparent,
       border: Border.all(
         color: isCompleted
             ? AppColors.accent
             : AppColors.textPrimary.withOpacity(0.6),
         width: 2,
       ),
     ),
     child: isCompleted
         ? const Icon(Icons.check, size: 14, color: Colors.black)
         : null,
   );
 }
}


class TagChip extends StatelessWidget {
 const TagChip({super.key, required this.tag});


 final TagInfo tag;


 @override
 Widget build(BuildContext context) {
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
     decoration: BoxDecoration(
       color: AppColors.sidebarActive,
       borderRadius: BorderRadius.circular(14),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         if (tag.icon != null) ...[
           Icon(tag.icon, size: 14, color: AppColors.textSecondary),
           const SizedBox(width: 6),
         ],
         Text(
           tag.label,
           style: Theme.of(context).textTheme.labelMedium?.copyWith(
             color: AppColors.textSecondary,
             fontWeight: FontWeight.w600,
           ),
         ),
       ],
     ),
   );
 }
}


class ActionChipButton extends StatelessWidget {
 const ActionChipButton({super.key, required this.icon, required this.label});


 final IconData icon;
 final String label;


 @override
 Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       color: AppColors.surface,
       borderRadius: BorderRadius.circular(18),
     ),
     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(icon, size: 18, color: AppColors.textSecondary),
         const SizedBox(width: 8),
         Text(
           label,
           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
             color: AppColors.textSecondary,
             fontWeight: FontWeight.w600,
           ),
         ),
       ],
     ),
   );
 }
}


class NavItemData {
 const NavItemData(this.icon, this.label, {this.badge, this.isActive = false});


 final IconData icon;
 final String label;
 final String? badge;
 final bool isActive;
}


class TaskItem {
 const TaskItem({
   required this.title,
   required this.icon,
   this.score,
   this.progress,
   this.progressLabel,
   this.metadata = const [],
   this.completed = false,
 });


 final String title;
 final IconData icon;
 final int? score;
 final double? progress;
 final String? progressLabel;
 final List<TagInfo> metadata;
 final bool completed;
}


class TagInfo {
 const TagInfo({required this.label, this.icon});


 final String label;
 final IconData? icon;
}


class SubtaskItem {
 const SubtaskItem({required this.title, this.completed = false});


 final String title;
 final bool completed;
}


class AppColors {
 static const Color background = Color(0xFF0D1D23);
 static const Color sidebar = Color(0xFF152833);
 static const Color sidebarActive = Color(0xFF203743);
 static const Color surface = Color(0xFF12242B);
 static const Color detailCard = Color(0xFF1B2E37);
 static const Color taskCard = Color(0xFF5D9A66);
 static const Color taskCardHighlight = Color(0xFF7FC38B);
 static const Color completedCard = Color(0xFF23383F);
 static const Color completedBorder = Color(0xFF40605F);
 static const Color finishedBadge = Color(0xFF4F7C57);
 static const Color scoreBadge = Color(0xFF30503F);
 static const Color subtaskBackground = Color(0xFF22353C);
 static const Color accent = Color(0xFFFFC857);
 static const Color textPrimary = Color(0xFFE6F1F1);
 static const Color textSecondary = Color(0xFFB1C6C6);
 static const Color textMuted = Color(0xFF80999B);
 static const Color progressTrack = Color(0xFF24423E);
}


// Placeholder screens for navigation destinations
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Calendar')),
    );
  }
}

class OutlookScreen extends StatelessWidget {
  const OutlookScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Outlook')),
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('All Tasks')),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Goals')),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Achievements')),
    );
  }
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Games')),
    );
  }
}

class PopOutScreen extends StatelessWidget {
  const PopOutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Pop out')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings')),
    );
  }
}

class SignOutScreen extends StatelessWidget {
  const SignOutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sign Out')),
    );
  }
}
