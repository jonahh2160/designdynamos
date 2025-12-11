import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/data/services/achievements_service.dart';
import 'package:designdynamos/providers/achievements_provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AchievementsProvider>().refresh();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;
    final tts = context.read<TtsProvider>();
    if (!tts.isEnabled) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tts.speak('Achievements screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementsProvider>();
    final theme = Theme.of(context);
    final snapshot = provider.snapshot;
    final tts = context.read<TtsProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  header: true,
                  label: 'Achievements screen',
                  child: Text(
                    'Achievements',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (provider.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 10,
                    child: _LeaderboardCard(entries: snapshot?.leaderboard ?? const [], tts: tts),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 13,
                    child: _BadgesCard(badges: snapshot?.badges ?? const [], tts: tts),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _StreakCard(
                      currentStreak: snapshot?.currentStreak ?? 0,
                      recentDays: snapshot?.recentDays ?? const [],
                      tts: tts,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: title,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries, required this.tts});

  final List<LeaderboardEntry> entries;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Coin Leaderboard',
      child: entries.isEmpty
          ? Center(
              child: Text(
                'No leaderboard data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final label = 'Rank ${index + 1}, ${entry.name}${entry.isCurrentUser ? ", you" : ""}, ${entry.coins} coins';
                return MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak(label);
                  },
                  child: Semantics(
                    label: label,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.detailCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.8)),
                      ),
                      child: Row(
                    children: [
                      _RankIcon(rank: index + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: entry.isCurrentUser
                                    ? AppColors.taskCardHighlight
                                    : AppColors.textPrimary,
                                fontWeight:
                                    entry.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                              ),
                        ),
                      ),
                        Text(
                          entry.coins.toString(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.monetization_on, color: AppColors.accent),
                      ],
                    ),
                  ),
                  ),
                );
              },
            ),
    );
  }
}

class _BadgesCard extends StatelessWidget {
  const _BadgesCard({required this.badges, required this.tts});

  final List<AchievementBadge> badges;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Your Badges',
      child: badges.isEmpty
          ? Center(
              child: Text(
                'No badges yet. Keep completing tasks!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.8,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _BadgeTile(badge: badge, tts: tts);
              },
            ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.currentStreak,
    required this.recentDays,
    required this.tts,
  });

  final int currentStreak;
  final List<DayStreakStatus> recentDays;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      title: 'Streak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.basic,
            onEnter: (_) {
              if (tts.isEnabled) tts.speak('Current streak, $currentStreak day${currentStreak == 1 ? '' : 's'}');
            },
            child: Semantics(
              label: 'Current streak, $currentStreak day${currentStreak == 1 ? '' : 's'}',
              child: Text(
                '$currentStreak day${currentStreak == 1 ? '' : 's'}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete at least one task on working days to keep the fire burning. Break days pause your streak.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: recentDays.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final day = recentDays[index];
                final status = day.isBreakDay ? 'break day, streak paused' : (day.completed ? 'completed' : 'not completed');
                final label = '${day.label}, $status';
                return MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak(label);
                  },
                  child: Semantics(
                    label: label,
                    child: Row(
                      children: [
                        _FlameIcon(
                          active: day.completed,
                          isBreak: day.isBreakDay,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (day.isBreakDay)
                            Text(
                              'Break day (streak paused)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankIcon extends StatelessWidget {
  const _RankIcon({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        color = const Color(0xFFFFD700);
        break;
      case 2:
        icon = Icons.emoji_events;
        color = const Color(0xFFC0C0C0);
        break;
      case 3:
        icon = Icons.emoji_events;
        color = const Color(0xFFCD7F32);
        break;
      default:
        icon = Icons.emoji_events_outlined;
        color = AppColors.textSecondary;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withOpacity(0.18),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.tts});

  final AchievementBadge badge;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = badge.earned ? AppColors.taskCardHighlight : AppColors.textMuted;
    final label = '${badge.title}, ${badge.subtitle}, ${badge.earned ? "obtained" : "not yet obtained"}';

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        if (tts.isEnabled) tts.speak(label);
      },
      child: Semantics(
        label: label,
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.detailCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.earned ? AppColors.taskCardHighlight : AppColors.sidebarActive,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: activeColor.withOpacity(0.2),
            child: Icon(
              badge.earned ? Icons.military_tech : Icons.lock_clock,
              color: activeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
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

class _FlameIcon extends StatelessWidget {
  const _FlameIcon({
    required this.active,
    this.isBreak = false,
  });

  final bool active;
  final bool isBreak;

  @override
  Widget build(BuildContext context) {
    final color = isBreak
        ? AppColors.taskCardHighlight
        : (active ? Colors.orangeAccent : AppColors.textMuted);
    final icon = isBreak ? Icons.beach_access : Icons.local_fire_department;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }
}
