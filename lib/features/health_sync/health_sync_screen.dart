import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/health_sync_snapshot.dart';
import '../../state/habit_provider.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  bool _loading = true;
  bool _busy = false;

  bool get _isApplePlatform {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  bool get _isAndroidPlatform => Theme.of(context).platform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateDevice());
  }

  Future<void> _validateDevice() async {
    setState(() => _loading = true);
    await context.read<HabitProvider>().validateHealthSyncDevice();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _installHealthConnect() async {
    setState(() => _busy = true);
    final installed = await context.read<HabitProvider>().installHealthConnect();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          installed
              ? 'Health Connect opened so Momentum can read Google Health step data.'
              : 'Health Connect is only needed on Android.',
        ),
      ),
    );
  }

  Future<void> _connectAndSync() async {
    setState(() => _busy = true);
    final result = await context.read<HabitProvider>().connectAndSyncSteps();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await context.read<HabitProvider>().disconnectHealthSync();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health sync disconnected')),
    );
  }

  Future<void> _handleRefresh() async {
    await context.read<HabitProvider>().refreshSyncedData();
    await _validateDevice();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Health sync'),
        backgroundColor: palette.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<HabitProvider>(
              builder: (context, provider, _) {
                final snapshot = provider.healthSyncSnapshot;
                final stepHabitCount = provider.habits.where(provider.isStepHabit).length;

                final history = provider.stepHistoryForRecentDays(days: 30);

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      _HeaderCard(
                        sourceLabel: snapshot.sourceLabel,
                        availability: _availabilityLabel(snapshot),
                        permissionState: _permissionLabel(snapshot.permissionState),
                        description: _platformDescription(snapshot),
                        icon: _platformIcon,
                      ),
                      const SizedBox(height: 16),
                      _StatusGrid(
                        snapshot: snapshot,
                        stepHabitCount: stepHabitCount,
                      ),
                      const SizedBox(height: 16),
                      _EvidenceCard(
                        snapshot: snapshot,
                        stepHabitCount: stepHabitCount,
                      ),
                      const SizedBox(height: 16),
                      _StepHistoryCalendarCard(
                        history: history,
                        connected: snapshot.connected,
                        sourceLabel: _historySourceLabel,
                      ),
                      const SizedBox(height: 18),
                      if (snapshot.availability == 'needs_install')
                        _PrimaryAction(
                          label: 'Enable Google Health Sync',
                          onPressed: _busy ? null : _installHealthConnect,
                        )
                      else
                        _PrimaryAction(
                          label: _primarySyncLabel(snapshot),
                          onPressed: _busy ? null : _connectAndSync,
                        ),
                      const SizedBox(height: 12),
                      _SecondaryAction(
                        label: _disconnectLabel,
                        onPressed: snapshot.connected && !_busy ? _disconnect : null,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _availabilityLabel(HealthSyncSnapshot snapshot) {
    switch (snapshot.availability) {
      case 'available':
        return 'Ready';
      case 'needs_install':
        return 'Needs install';
      case 'unsupported':
        return 'Unsupported';
      default:
        return 'Checking';
    }
  }

  String _permissionLabel(String permissionState) {
    switch (permissionState) {
      case 'granted':
        return 'Granted';
      case 'denied':
        return 'Denied';
      case 'unsupported':
        return 'Unsupported';
      default:
        return 'Not requested';
    }
  }

  IconData get _platformIcon {
    if (_isApplePlatform) {
      return Icons.apple_rounded;
    }
    if (_isAndroidPlatform) {
      return Icons.android_rounded;
    }
    return Icons.favorite_rounded;
  }

  String get _historySourceLabel {
    if (_isApplePlatform) {
      return 'Apple Fitness';
    }
    if (_isAndroidPlatform) {
      return 'Google Health';
    }
    return 'your health source';
  }

  String _platformDescription(HealthSyncSnapshot snapshot) {
    if (_isApplePlatform) {
      return snapshot.connected
          ? 'Apple Fitness linked.'
          : 'Connect Apple Fitness.';
    }
    if (_isAndroidPlatform) {
      return snapshot.availability == 'needs_install'
          ? 'Install Health Connect first.'
          : snapshot.connected
              ? 'Google Health linked.'
              : 'Connect Google Health.';
    }
    return 'Connect health access.';
  }

  String _primarySyncLabel(HealthSyncSnapshot snapshot) {
    if (_isApplePlatform) {
      return snapshot.connected ? 'Sync from Apple Fitness' : 'Sync with Apple Fitness';
    }
    if (_isAndroidPlatform) {
      return snapshot.connected ? 'Sync from Google Health' : 'Sync with Google Health';
    }
    return snapshot.connected ? 'Sync latest step history' : 'Connect and sync steps';
  }

  String get _disconnectLabel {
    if (_isApplePlatform) {
      return 'Disconnect Apple Fitness';
    }
    if (_isAndroidPlatform) {
      return 'Disconnect Google Health';
    }
    return 'Disconnect health sync';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.sourceLabel,
    required this.availability,
    required this.permissionState,
    required this.description,
    required this.icon,
  });

  final String sourceLabel;
  final String availability;
  final String permissionState;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.isMomentumDark
                      ? palette.accentSoft
                      : AppColors.emberDim,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceLabel,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$availability / $permissionState',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.snapshot,
    required this.stepHabitCount,
  });

  final HealthSyncSnapshot snapshot;
  final int stepHabitCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Step habits',
            value: '$stepHabitCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Last steps',
            value: snapshot.lastSyncedSteps?.toString() ?? '0',
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.snapshot,
    required this.stepHabitCount,
  });

  final HealthSyncSnapshot snapshot;
  final int stepHabitCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection',
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _ValidationRow(
            label: 'Platform source',
            value: snapshot.sourceLabel,
          ),
          _ValidationRow(
            label: 'Availability',
            value: snapshot.availability,
          ),
          _ValidationRow(
            label: 'Permission',
            value: snapshot.permissionState,
          ),
          _ValidationRow(
            label: 'Connected step habits',
            value: '$stepHabitCount',
          ),
          _ValidationRow(
            label: 'Last sync',
            value: snapshot.lastSyncedAt == null
                ? 'Not synced yet'
                : DateFormat('EEE, d MMM / HH:mm').format(snapshot.lastSyncedAt!),
            isLast: snapshot.lastError == null || snapshot.lastError!.isEmpty,
          ),
          if (snapshot.lastError != null && snapshot.lastError!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              snapshot.lastError!,
              style: TextStyle(
                color: palette.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepHistoryCalendarCard extends StatelessWidget {
  const _StepHistoryCalendarCard({
    required this.history,
    required this.connected,
    required this.sourceLabel,
  });

  final Map<DateTime, int> history;
  final bool connected;
  final String sourceLabel;

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
              fontSize: 11,
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
      cells.add(_CalendarDayCell(
        day: day,
        steps: steps,
        isToday: isToday,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step history',
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            connected
                ? 'This month from $sourceLabel.'
                : 'Connect $sourceLabel to fill this month.',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
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
    final hasSteps = steps > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: hasSteps
            ? (context.isMomentumDark ? palette.successSoft : AppColors.mossDim)
            : (context.isMomentumDark ? palette.surfaceMuted : palette.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? palette.accent
              : hasSteps
                  ? palette.success.withValues(alpha: 0.24)
                  : palette.border,
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: palette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasSteps ? _formatCompactSteps(steps) : '-',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasSteps ? palette.success : palette.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactSteps(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      return compact == compact.roundToDouble()
          ? '${compact.toStringAsFixed(0)}k'
          : '${compact.toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: palette.border.withValues(alpha: 0.8),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: palette.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return SizedBox(
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
