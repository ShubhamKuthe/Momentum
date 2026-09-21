import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../models/habit.dart';
import '../../state/habit_provider.dart';
import '../../widgets/animated_count_text.dart';
import '../../widgets/streak_momentum_effect.dart';
import '../adaptive_goals/adaptive_goal_history_screen.dart';
import '../create_edit_habit/create_edit_habit_screen.dart';
import '../health_sync/health_sync_screen.dart';
import '../reminders/reminder_setup_screen.dart';

BoxDecoration _detailPanelDecoration(
  BuildContext context, {
  double radius = 18,
  Color? color,
}) {
  final palette = context.momentum;
  return BoxDecoration(
    color: color ?? palette.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: palette.border),
    boxShadow: [
      BoxShadow(
        color: palette.shadow.withValues(
          alpha: context.isMomentumDark ? 0.2 : 0.07,
        ),
        blurRadius: context.isMomentumDark ? 16 : 12,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  String? _adaptiveFeedback;
  bool _adaptiveBusy = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showAdaptiveFeedback(String message) {
    _feedbackTimer?.cancel();
    setState(() => _adaptiveFeedback = message);
    _feedbackTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() => _adaptiveFeedback = null);
      }
    });
  }

  Future<void> _runAdaptiveAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_adaptiveBusy) {
      return;
    }

    setState(() => _adaptiveBusy = true);
    await action();
    if (!mounted) {
      return;
    }
    setState(() => _adaptiveBusy = false);
    _showAdaptiveFeedback(successMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final palette = context.momentum;
        final habit = provider.habitById(widget.habitId);
        if (habit == null) {
          return Scaffold(
            backgroundColor: palette.background,
            body: Center(
              child: Text(
                'Habit not found.',
                style: TextStyle(color: palette.text),
              ),
            ),
          );
        }

        final responsive = context.responsive;
        final compact = responsive.width < 390;
        final ratios = provider.last7RatiosForHabit(habit);
        final suggestionAvailable = provider.averageRatioForHabit(habit) > 0.85;
        final suggestedTarget = provider.suggestedTarget(habit);
        final logs = provider.logsForHabit(habit.id);
        final history = provider.adaptiveHistoryForHabit(habit.id);
        final todayProgress = provider.progressForToday(habit);
        final remaining = provider.remainingForToday(habit);
        final automaticity = provider.automaticityScore(habit).round();
        final cueStrength = provider.cueStrengthScore(habit);
        final cueStrengthLabel = provider.cueStrengthLabel(habit);
        final isStepHabit = provider.isStepHabit(habit);
        final canManualLog = provider.canManualLogHabit(habit);
        final stepSnapshot = provider.healthSyncSnapshot;
        final stepHistory = isStepHabit
            ? provider.stepHistoryForRecentDays(days: 30)
            : const <DateTime, int>{};

        return Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refreshSyncedData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  responsive.pagePadding,
                  responsive.value(12, min: 10, max: 14),
                  responsive.pagePadding,
                  responsive.value(120, min: 104, max: 134),
                ),
                children: [
                Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _RoundIconButton(
                      icon: Icons.edit_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateEditHabitScreen(habit: habit),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  habit.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${habit.frequency} - ${habit.cue.isEmpty ? 'No cue yet' : habit.cue}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _HeroProgressCard(
                  habit: habit,
                  compact: compact,
                  todayProgress: todayProgress,
                  remaining: remaining,
                  automaticity: automaticity,
                ),
                if (isStepHabit) ...[
                  const SizedBox(height: 22),
                  const _SectionHeading('Step history'),
                  const SizedBox(height: 10),
                  _StepHistorySnapshotCard(
                    history: stepHistory,
                    snapshotLabel: stepSnapshot.sourceLabel,
                    connected: stepSnapshot.connected,
                    todayProgress: todayProgress,
                  ),
                ],
                const SizedBox(height: 22),
                const _SectionHeading('Quick setup'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.notifications_active_rounded,
                        title: 'Reminders',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReminderSetupScreen(
                                habit: habit,
                                provider: provider,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.favorite_rounded,
                        title: 'Health sync',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HealthSyncScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.timeline_rounded,
                  title: 'Adaptive goal history',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdaptiveGoalHistoryScreen(entries: history),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                const _SectionHeading('Behavior insight'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _detailPanelDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SheetMetric(
                              label: 'Cue strength',
                              value: '$cueStrength%',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetMetric(
                              label: 'Status',
                              value: cueStrengthLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionHeading('This week'),
                const SizedBox(height: 12),
                _AnimatedWeekBars(ratios: ratios),
                const SizedBox(height: 22),
                const _SectionHeading('Adaptive goals'),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _adaptiveFeedback != null
                      ? _AdaptiveSuccessCard(
                          key: ValueKey(_adaptiveFeedback),
                          message: _adaptiveFeedback!,
                        )
                      : suggestionAvailable
                          ? _AdaptiveGoalCard(
                              key: ValueKey(
                                'adaptive-${habit.id}-${habit.targetValue}-$suggestedTarget',
                              ),
                              compact: compact,
                              oldTarget: habit.targetValue,
                              suggestedTarget: suggestedTarget,
                              unit: habit.unit,
                              busy: _adaptiveBusy,
                              onAccept: () => _runAdaptiveAction(
                                () => provider.acceptAdaptiveSuggestion(habit),
                                'Target raised to $suggestedTarget ${habit.unit}. Your approval was saved.',
                              ),
                              onKeep: () => _runAdaptiveAction(
                                () => provider.keepAdaptiveSuggestion(habit),
                                'Current target kept. Momentum recorded your choice.',
                              ),
                              onReject: () => _runAdaptiveAction(
                                () => provider.rejectAdaptiveSuggestion(habit),
                                'Suggestion rejected. Your target stays unchanged.',
                              ),
                            )
                          : const _EmptyStateCard(
                              key: ValueKey('adaptive-empty'),
                              icon: Icons.timeline_rounded,
                              title: 'No adaptive suggestions yet',
                              body:
                                  'Momentum will only suggest a target change after a strong pattern of over-achievement. Any proposal will still need your approval.',
                            ),
                ),
                const SizedBox(height: 22),
                const _SectionHeading('Recent log'),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const _EmptyStateCard(
                    icon: Icons.edit_note_rounded,
                    title: 'No progress logs yet',
                    body:
                        'Start with one manual entry today and Momentum will turn it into a visible streak and history.',
                  )
                else
                  ...logs.take(5).map((log) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: _detailPanelDecoration(context, radius: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.isMomentumDark
                                  ? palette.successSoft
                                  : AppColors.mossDim,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: palette.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '+${log.value} ${habit.unit}',
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(log.date),
                                  style: TextStyle(
                                    color: palette.textSoft,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          bottomNavigationBar: canManualLog
              ? SafeArea(
                  minimum: EdgeInsets.fromLTRB(
                    context.responsive.pagePadding,
                    context.responsive.value(10, min: 8, max: 12),
                    context.responsive.pagePadding,
                    context.responsive.bottomSafeGap,
                  ),
                  child: SizedBox(
                    height: context.responsive.minButtonHeight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ember,
                        foregroundColor: context.isMomentumDark
                            ? Colors.white
                            : const Color(0xFF1A0D08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.responsive.radius(16),
                          ),
                        ),
                      ),
                      onPressed: () => _showLogBottomSheet(context, provider, habit),
                      child: Text(_logButtonLabel(habit)),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  String _logButtonLabel(Habit habit) {
    final unit = habit.unit.trim().toLowerCase();
    if (unit.isEmpty || unit == 'progress') {
      return "Log today's progress";
    }
    return "Log today's $unit";
  }

  Future<void> _showLogBottomSheet(
    BuildContext context,
    HabitProvider provider,
    Habit habit,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return MomentumSheetFrame(
          child: _AnimatedLogBottomSheet(
            habit: habit,
            provider: provider,
            logButtonLabel: _logButtonLabel(habit),
          ),
        );
      },
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${habit.name} updated for today')),
      );
    }
  }
}

class _HeroProgressCard extends StatelessWidget {
  const _HeroProgressCard({
    required this.habit,
    required this.compact,
    required this.todayProgress,
    required this.remaining,
    required this.automaticity,
  });

  final Habit habit;
  final bool compact;
  final int todayProgress;
  final int remaining;
  final int automaticity;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final progressRatio = habit.targetValue == 0
        ? 0.0
        : (todayProgress / habit.targetValue).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isMomentumDark
              ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
              : [AppColors.inkText, const Color(0xFF2E3444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isMomentumDark
              ? palette.borderSoft.withValues(alpha: 0.7)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroProgressHeadline(
                  compact: compact,
                  todayProgress: todayProgress,
                  habit: habit,
                ),
                const SizedBox(height: 12),
                StreakMomentumEffect(
                  streak: habit.currentStreak,
                  compact: compact,
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeroProgressHeadline(
                    compact: compact,
                    todayProgress: todayProgress,
                    habit: habit,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: StreakMomentumEffect(
                      streak: habit.currentStreak,
                      compact: compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _HeroProgressMeter(
            value: progressRatio,
            compact: compact,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Automaticity',
                  child: AnimatedCountText(
                    value: automaticity.toDouble(),
                    suffix: '%',
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Target',
                  child: Text(
                    habit.targetLabel,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$remaining ${habit.unit} remaining today',
            style: const TextStyle(
              color: Color(0xFFB9BEC9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroProgressHeadline extends StatelessWidget {
  const _HeroProgressHeadline({
    required this.compact,
    required this.todayProgress,
    required this.habit,
  });

  final bool compact;
  final int todayProgress;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 2,
          runSpacing: 2,
          children: [
            AnimatedCountText(
              value: todayProgress.toDouble(),
              style: TextStyle(
                color: AppColors.paper,
                fontSize: compact ? 20 : 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '/ ${habit.targetValue} ${habit.unit}',
              style: TextStyle(
                color: AppColors.paper,
                fontSize: compact ? 20 : 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'today\'s progress',
          style: TextStyle(
            color: Color(0xFFB9BEC9),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroProgressMeter extends StatelessWidget {
  const _HeroProgressMeter({
    required this.value,
    required this.compact,
  });

  final double value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: compact ? 8 : 9,
        color: Colors.white.withValues(alpha: 0.12),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.ember, Color(0xFFFF8A6F)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ember.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedWeekBars extends StatelessWidget {
  const _AnimatedWeekBars({required this.ratios});

  final List<double> ratios;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(ratios.length, (index) {
          final day = DateFormat.E().format(
            DateTime.now().subtract(Duration(days: 6 - index)),
          );
          return Expanded(
            child: _AnimatedDayBar(
              index: index,
              ratio: ratios[index],
              label: day.substring(0, 1),
            ),
          );
        }),
      ),
    );
  }
}

class _StepHistorySnapshotCard extends StatelessWidget {
  const _StepHistorySnapshotCard({
    required this.history,
    required this.snapshotLabel,
    required this.connected,
    required this.todayProgress,
  });

  final Map<DateTime, int> history;
  final String snapshotLabel;
  final bool connected;
  final int todayProgress;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final now = DateTime.now();
    final currentMonth = history.entries
        .where((entry) => entry.key.year == now.year && entry.key.month == now.month)
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final orderedEntries = history.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final recent30 = orderedEntries.length > 30
        ? orderedEntries.sublist(orderedEntries.length - 30)
        : orderedEntries;
    final monthTotal = currentMonth.fold<int>(0, (sum, entry) => sum + entry.value);
    final monthlyAverage = recent30.isEmpty
        ? 0
        : (recent30.fold<int>(0, (sum, entry) => sum + entry.value) / recent30.length)
            .round();
    final bestEntry = currentMonth.isEmpty
        ? null
        : currentMonth.reduce((best, candidate) {
            return candidate.value > best.value ? candidate : best;
          });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _detailPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected ? snapshotLabel : 'Health sync not connected',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connected
                          ? 'Momentum is showing your synced step history for this month.'
                          : 'Connect Google Health or Apple Health to fill this calendar.',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: connected ? palette.successSoft : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  connected ? 'Synced' : 'Manual',
                  style: TextStyle(
                    color: connected ? palette.success : palette.textSoft,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StepHistoryMetricTile(
                  label: 'Today',
                  value: NumberFormat.decimalPattern().format(todayProgress),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepHistoryMetricTile(
                  label: '30-day avg',
                  value: NumberFormat.decimalPattern().format(monthlyAverage),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepHistoryMetricTile(
                  label: 'Month',
                  value: NumberFormat.decimalPattern().format(monthTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bestEntry != null)
            Text(
              'Best day: ${DateFormat('d MMM').format(bestEntry.key)} - ${NumberFormat.decimalPattern().format(bestEntry.value)} steps',
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 14),
          _StepHistoryBars(entries: recent30),
          const SizedBox(height: 16),
          _StepHistoryMonthGrid(history: history),
        ],
      ),
    );
  }
}

class _StepHistoryMetricTile extends StatelessWidget {
  const _StepHistoryMetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.isMomentumDark ? palette.surfaceStrong : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHistoryBars extends StatelessWidget {
  const _StepHistoryBars({required this.entries});

  final List<MapEntry<DateTime, int>> entries;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final items = List<MapEntry<DateTime, int>>.from(entries);
    while (items.length < 7) {
      final seedDate = items.isEmpty
          ? DateTime.now().subtract(Duration(days: 6 - items.length))
          : items.first.key.subtract(const Duration(days: 1));
      items.insert(0, MapEntry(DateTime(seedDate.year, seedDate.month, seedDate.day), 0));
    }
    final maxValue = items.fold<int>(0, (maxSoFar, entry) => max(maxSoFar, entry.value));

    return SizedBox(
      height: 108,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(items.length, (index) {
          final entry = items[index];
          final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
          final label = DateFormat.d().format(entry.key);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: ratio),
                        duration: Duration(milliseconds: 380 + (index * 50)),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedRatio, _) {
                          final height = 8 + (animatedRatio * 56);
                          return Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: entry.value > 0 ? palette.accent : palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepHistoryMonthGrid extends StatelessWidget {
  const _StepHistoryMonthGrid({required this.history});

  final Map<DateTime, int> history;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final leadingEmptySlots = firstDay.weekday - 1;
    final cells = <Widget>[
      for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
          child: Text(
            label,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ];

    for (var i = 0; i < leadingEmptySlots; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final steps = history[date] ?? 0;
      final isToday = day == now.day;
      cells.add(
        _StepHistoryDayCell(
          day: day,
          steps: steps,
          isToday: isToday,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: cells,
    );
  }
}

class _StepHistoryDayCell extends StatelessWidget {
  const _StepHistoryDayCell({
    required this.day,
    required this.steps,
    required this.isToday,
  });

  final int day;
  final int steps;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      decoration: BoxDecoration(
        color: context.isMomentumDark ? palette.surfaceStrong : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? palette.accent : Colors.transparent,
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            steps > 0 ? NumberFormat.compact().format(steps) : '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: steps > 0 ? palette.textSoft : palette.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDayBar extends StatelessWidget {
  const _AnimatedDayBar({
    required this.index,
    required this.ratio,
    required this.label,
  });

  final int index;
  final double ratio;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hit = ratio >= 1;
    final palette = context.momentum;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 420 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final height = 22 + animated * 62;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: hit
                        ? palette.success
                        : (context.isMomentumDark
                            ? palette.surfaceMuted
                            : AppColors.paperDim),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdaptiveGoalCard extends StatefulWidget {
  const _AdaptiveGoalCard({
    super.key,
    required this.compact,
    required this.oldTarget,
    required this.suggestedTarget,
    required this.unit,
    required this.busy,
    required this.onAccept,
    required this.onKeep,
    required this.onReject,
  });

  final bool compact;
  final int oldTarget;
  final int suggestedTarget;
  final String unit;
  final bool busy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onKeep;
  final Future<void> Function() onReject;

  @override
  State<_AdaptiveGoalCard> createState() => _AdaptiveGoalCardState();
}

class _AdaptiveGoalCardState extends State<_AdaptiveGoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emberDim,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFCBB8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Approval required',
                style: TextStyle(
                  color: Color(0xFF7A2E14),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You beat your goal most days this week. Momentum suggests raising the target from ${widget.oldTarget} to ${widget.suggestedTarget} ${widget.unit}.',
                style: const TextStyle(
                  color: Color(0xFF7A2E14),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your choice is recorded so adaptive changes stay user-approved.',
                style: TextStyle(
                  color: Color(0xFF98523D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: widget.compact ? double.infinity : 110,
                    child: _MomentumActionButton(
                      label: 'Accept',
                      filled: true,
                      busy: widget.busy,
                      onPressed: widget.onAccept,
                    ),
                  ),
                  SizedBox(
                    width: widget.compact ? double.infinity : 124,
                    child: _MomentumActionButton(
                      label: 'Keep current',
                      outlined: true,
                      busy: widget.busy,
                      onPressed: widget.onKeep,
                    ),
                  ),
                  SizedBox(
                    width: widget.compact ? double.infinity : 108,
                    child: _MomentumActionButton(
                      label: 'Reject',
                      subtle: true,
                      busy: widget.busy,
                      onPressed: widget.onReject,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentumActionButton extends StatefulWidget {
  const _MomentumActionButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.filled = false,
    this.outlined = false,
    this.subtle = false,
  });

  final String label;
  final Future<void> Function() onPressed;
  final bool busy;
  final bool filled;
  final bool outlined;
  final bool subtle;

  @override
  State<_MomentumActionButton> createState() => _MomentumActionButtonState();
}

class _MomentumActionButtonState extends State<_MomentumActionButton> {
  bool _pressed = false;

  Future<void> _handlePress() async {
    if (widget.busy) {
      return;
    }
    await widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    Color background;
    Color foreground;
    BorderSide side;

    if (widget.filled) {
      background = context.isMomentumDark ? palette.text : AppColors.inkText;
      foreground = context.isMomentumDark ? palette.background : AppColors.paper;
      side = BorderSide.none;
    } else if (widget.outlined) {
      background = Colors.transparent;
      foreground = context.isMomentumDark ? palette.accent : const Color(0xFF7A2E14);
      side = BorderSide(
        color: context.isMomentumDark
            ? palette.borderSoft
            : const Color(0xFFE3987A),
      );
    } else {
      background = Colors.transparent;
      foreground = context.isMomentumDark ? palette.textSoft : const Color(0xFF7A2E14);
      side = BorderSide.none;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _handlePress,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: side == BorderSide.none ? null : Border.fromBorderSide(side),
          ),
          alignment: Alignment.center,
          child: widget.busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.filled
                        ? (context.isMomentumDark ? palette.background : AppColors.paper)
                        : foreground,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AdaptiveSuccessCard extends StatelessWidget {
  const _AdaptiveSuccessCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isMomentumDark ? palette.successSoft : AppColors.mossDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.success.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogBottomSheet extends StatefulWidget {
  const _AnimatedLogBottomSheet({
    required this.habit,
    required this.provider,
    required this.logButtonLabel,
  });

  final Habit habit;
  final HabitProvider provider;
  final String logButtonLabel;

  @override
  State<_AnimatedLogBottomSheet> createState() => _AnimatedLogBottomSheetState();
}

class _AnimatedLogBottomSheetState extends State<_AnimatedLogBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _isSaving = false;

  int get _current => widget.provider.progressForToday(widget.habit);
  int get _remaining => widget.provider.remainingForToday(widget.habit);

  int get _typedValue => int.tryParse(_controller.text.trim()) ?? 0;
  int get _stepAmount {
    final target = widget.habit.targetValue;
    if (target >= 5000) {
      return 500;
    }
    if (target >= 1000) {
      return 100;
    }
    if (target >= 100) {
      return 10;
    }
    if (target >= 20) {
      return 5;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '$_current')
      ..addListener(_handleInputChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    final curved = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);
    _animationController.forward();
  }

  void _handleInputChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleInputChange)
      ..dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid ${widget.habit.unit} value'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.provider.setProgressForToday(widget.habit, value);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _adjustValue(int delta) {
    final nextValue = max(0, _typedValue + delta);
    _controller.value = TextEditingValue(
      text: '$nextValue',
      selection: TextSelection.collapsed(offset: '$nextValue'.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final previewRemaining = max(0, _remaining - _typedValue);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.borderSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.logButtonLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Target ${widget.habit.targetValue} ${widget.habit.unit}',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SheetMetric(
                        label: 'Current',
                        value: '$_current ${widget.habit.unit}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SheetMetric(
                        label: 'Target',
                        value: '${widget.habit.targetValue} ${widget.habit.unit}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SheetMetric(
                        label: 'Remaining',
                        value: '$previewRemaining ${widget.habit.unit}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Today\'s total',
                    hintText: 'Enter ${widget.habit.unit}',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SheetStepperButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _adjustValue(-_stepAmount),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SheetStepperButton(
                        icon: Icons.add_rounded,
                        onTap: () => _adjustValue(_stepAmount),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.text,
                      foregroundColor: palette.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.background,
                            ),
                          )
                        : const Text('Save today'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _detailPanelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.isMomentumDark ? palette.accentSoft : AppColors.emberDim,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: palette.accent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: palette.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetStepperButton extends StatelessWidget {
  const _SheetStepperButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Icon(icon, color: palette.text),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: context.isMomentumDark ? palette.textSoft : const Color(0xFFB9BEC9),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _SheetMetric extends StatelessWidget {
  const _SheetMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _detailPanelDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _detailPanelDecoration(context),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.isMomentumDark ? palette.surfaceMuted : AppColors.paperDim,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: palette.textSoft),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Text(
      text,
      style: TextStyle(
        color: palette.textSoft,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.isMomentumDark ? palette.surfaceMuted : AppColors.paperDim,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: palette.text),
      ),
    );
  }
}
