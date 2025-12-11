import 'dart:math';

import 'package:designdynamos/core/models/progress_snapshot.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/providers/progress_provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _announced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProgressProvider>().refresh();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;
    final tts = context.read<TtsProvider>();
    print('Progress TTS isEnabled: ${tts.isEnabled}');
    if (!tts.isEnabled) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('Speaking: Progress and analytics screen');
        tts.speak('Progress and analytics screen');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final snapshot = provider.snapshot;
    final theme = Theme.of(context);
    final tts = context.read<TtsProvider>();

    final categoryOptions = [
      'All categories',
      ...snapshot.availableCategories.where(
        (name) => name.trim().isNotEmpty,
      ),
    ].toSet().toList(); //dedupe

    final categoryValue = snapshot.categoryFilter ?? 'All categories';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Semantics(
                  header: true,
                  label: 'Progress and analytics screen',
                  child: Text(
                    'Progress & Analytics',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (snapshot.fromCache)
                  Chip(
                    backgroundColor: AppColors.sidebarActive,
                    label: const Text(
                      'Cached',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                const Spacer(),
                if (provider.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: ProgressRange.values.map((range) {
                    final selected = snapshot.range == range;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) {
                        print('Day filter hover: ${range.label}, TTS enabled: ${tts.isEnabled}');
                        if (tts.isEnabled) tts.speak('${range.label} days filter, ${selected ? "selected" : "not selected"}');
                      },
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: '${range.label} days',
                        onTap: selected ? null : () => context.read<ProgressProvider>().refresh(range: range),
                        child: ChoiceChip(
                          label: Text(range.label),
                          selected: selected,
                          onSelected: (_) {
                            context.read<ProgressProvider>().refresh(range: range);
                          },
                          selectedColor: AppColors.taskCard,
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: selected ? Colors.black : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: AppColors.detailCard,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak('Select category dropdown');
                  },
                  child: Semantics(
                    label: 'Select category filter',
                    button: true,
                    child: DropdownButton<String>(
                      value: categoryOptions.contains(categoryValue)
                          ? categoryValue
                          : 'All categories',
                      dropdownColor: AppColors.detailCard,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      items: categoryOptions
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              onTap: () {
                                if (tts.isEnabled) tts.speak('Category $name');
                              },
                          child: Semantics(
                            label: 'Category $name',
                            child: Text(name),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final isReset = value == null || value == 'All categories';
                    final next = isReset ? null : value;
                    context.read<ProgressProvider>().refresh(
                          category: next,
                          resetCategory: isReset,
                        );
                  },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    if (tts.isEnabled) tts.speak('Refresh analytics button');
                  },
                  child: Semantics(
                    button: true,
                    enabled: !provider.isLoading,
                    label: 'Refresh analytics',
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                      onPressed: provider.isLoading
                          ? null
                          : () => context.read<ProgressProvider>().refresh(),
                      tooltip: 'Refresh analytics',
                    ),
                  ),
                ),
              ],
            ),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
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
                        onPressed: provider.isLoading
                            ? null
                            : () => context.read<ProgressProvider>().refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (!snapshot.hasActivity && !provider.isLoading)
              Expanded(
                child: _EmptyState(
                  onRefresh: () =>
                      context.read<ProgressProvider>().refresh(),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    _MetricsRow(snapshot: snapshot, tts: tts),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 13,
                            child: _CardShell(
                              title: 'Daily completions',
                              trailing: provider.isLoading
                                  ? const LinearProgressIndicator(
                                      minHeight: 3,
                                      color: AppColors.taskCardHighlight,
                                      backgroundColor: AppColors.progressTrack,
                                    )
                                  : null,
                              child: _BarChart(points: snapshot.daily),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 10,
                            child: _CardShell(
                              title: 'Category breakdown',
                              trailing: provider.isLoading
                                  ? const LinearProgressIndicator(
                                      minHeight: 3,
                                      color: AppColors.taskCardHighlight,
                                      backgroundColor: AppColors.progressTrack,
                                    )
                                  : null,
                              child: _CategoryList(
                                categories: snapshot.categories,
                                tts: tts,
                              ),
                            ),
                          ),
                        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, size: 54, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No history yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some tasks to unlock streaks, charts, and insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Check again'),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.snapshot, required this.tts});

  final ProgressSnapshot snapshot;
  final TtsProvider tts;

  String _formatPercent(double value) =>
      '${clampPercent(value)}%';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Completion Rate',
            value: _formatPercent(snapshot.completionRate),
            subtitle: 'Tasks finished in range',
            icon: Icons.check_circle,
            color: AppColors.taskCardHighlight,
            tts: tts,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Consistency',
            value: _formatPercent(snapshot.consistency),
            subtitle: 'Days with activity',
            icon: Icons.calendar_today,
            color: AppColors.accent,
            tts: tts,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Best Day',
            value: '${snapshot.bestDayCount}',
            subtitle: 'Most tasks in a day',
            icon: Icons.bar_chart,
            color: Colors.lightBlueAccent,
            tts: tts,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Streak',
            value: '${snapshot.currentStreak}d',
            subtitle: 'Current completion streak',
            icon: Icons.local_fire_department,
            color: Colors.orangeAccent,
            tts: tts,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tts,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        print('MetricCard hover: $title, TTS enabled: ${tts.isEnabled}');
        if (tts.isEnabled) {
          tts.speak('$title, $value, $subtitle');
        }
      },
      child: Semantics(
        label: '$title, $value, $subtitle',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sidebarActive.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (trailing != null) SizedBox(width: 180, child: trailing),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.points});

  final List<DailyStatPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data for this range',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CustomPaint(
        painter: _BarChartPainter(points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.points);

  final List<DailyStatPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.taskCardHighlight
      ..style = PaintingStyle.fill;

    final track = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      track,
    );

    final maxValue = points.map((p) => p.completed).fold<int>(
      0,
      (prev, element) => max(prev, element),
    );
    final usableHeight = size.height - 16;
    final barHeightFactor =
        maxValue == 0 ? 0.0 : usableHeight / maxValue;

    final barSpacing = 6.0;
    final barWidth = max(
      4.0,
      (size.width - (points.length - 1) * barSpacing) / points.length,
    );

    double x = 0;
    for (final point in points) {
      final height = ((point.completed * barHeightFactor)
              .clamp(0.0, usableHeight))
          .toDouble();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          usableHeight - height + 8,
          barWidth,
          height,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
      x += barWidth + barSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, required this.tts});

  final List<CategorySummary> categories;
  final TtsProvider tts;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories in this range',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final categoryLabel = '${cat.name}, ${cat.completed} of ${cat.total} tasks completed';
        return MouseRegion(
          cursor: SystemMouseCursors.basic,
          onEnter: (_) {
            if (tts.isEnabled) tts.speak(categoryLabel);
          },
          child: Semantics(
            label: categoryLabel,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.detailCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sidebarActive.withOpacity(0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Text(
                        '${cat.completed}/${cat.total}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: cat.completionRate.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: AppColors.progressTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.taskCardHighlight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
