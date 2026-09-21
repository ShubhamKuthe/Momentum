import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/habits/habit_customization.dart';
import '../core/habits/step_sync_logic.dart';
import '../models/adaptive_goal_entry.dart';
import '../models/habit.dart';
import '../models/health_sync_snapshot.dart';
import '../models/habit_log.dart';
import '../services/database_service.dart';
import '../services/health_sync_service.dart';
import '../services/reminder_service.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider({
    DatabaseService? databaseService,
    HealthSyncService? healthSyncService,
    ReminderService? reminderService,
    bool autoLoad = true,
  })  : _dbService = databaseService ?? DatabaseService(),
        _healthSyncService = healthSyncService ?? HealthSyncService.instance,
        _reminderService = reminderService ?? ReminderService.instance {
    if (autoLoad) {
      loadHabits();
    }
  }

  final DatabaseService _dbService;
  final HealthSyncService _healthSyncService;
  final ReminderService _reminderService;
  final Uuid _uuid = const Uuid();

  List<Habit> _habits = const [];
  final Map<String, List<HabitLog>> _logsByHabit = {};
  final Map<String, List<AdaptiveGoalEntry>> _adaptiveHistoryByHabit = {};
  Map<String, String> _completionMoods = const {};
  HealthSyncSnapshot _healthSyncSnapshot = HealthSyncSnapshot.initial();
  bool _isLoading = true;
  String? _errorMessage;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  HealthSyncSnapshot get healthSyncSnapshot => _healthSyncSnapshot;

  Future<void> loadHabits() async {
    await _reloadHabits(showLoadingIndicator: true);
  }

  Future<void> refreshSyncedData() async {
    await _reloadHabits(showLoadingIndicator: false);

    if (_healthSyncSnapshot.connected && _habits.any(isStepHabit)) {
      final result = await _healthSyncService.refreshConnectedSteps(
        previous: _healthSyncSnapshot,
      );
      await _applyStepSyncResult(result);
      return;
    }

    notifyListeners();
  }

  Future<void> _reloadHabits({
    required bool showLoadingIndicator,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (showLoadingIndicator) {
      notifyListeners();
    }

    try {
      final loadedHabits = await _dbService.getHabits();
      _healthSyncSnapshot = await _dbService.getHealthSyncSnapshot();
      _completionMoods = await _dbService.getCompletionMoodMap();
      final Map<String, List<HabitLog>> logs = {};
      final adaptiveEntries = await _dbService.getAdaptiveGoalEntries();
      final Map<String, List<AdaptiveGoalEntry>> history = {};

      for (final habit in loadedHabits) {
        logs[habit.id] = await _dbService.getLogsForHabit(habit.id);
        history[habit.id] = adaptiveEntries
            .where((entry) => entry.habitId == habit.id)
            .toList();
      }

      _habits = loadedHabits;
      _logsByHabit
        ..clear()
        ..addAll(logs);
      _adaptiveHistoryByHabit
        ..clear()
        ..addAll(history);
      try {
        await _reminderService.syncAllHabits(
          _habits,
          isCompletedToday: isCompletedToday,
        );
      } catch (error, stackTrace) {
        debugPrint('Momentum reminder sync skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (error, stackTrace) {
      debugPrint('Momentum habits load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _habits = const [];
      _logsByHabit.clear();
      _adaptiveHistoryByHabit.clear();
      _completionMoods = const {};
      _healthSyncSnapshot = HealthSyncSnapshot.initial();
      _errorMessage = 'Could not load saved habits on this device.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<HabitLog> logsForHabit(String habitId) {
    return List.unmodifiable(_logsByHabit[habitId] ?? const <HabitLog>[]);
  }

  List<AdaptiveGoalEntry> adaptiveHistoryForHabit(String habitId) {
    return List.unmodifiable(
      _adaptiveHistoryByHabit[habitId] ?? const <AdaptiveGoalEntry>[],
    );
  }

  Future<void> addHabit(Habit habit) async {
    await _dbService.insertHabit(habit);
    await loadHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _dbService.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _reminderService.cancelHabitReminder(id);
    await _dbService.deleteHabit(id);
    await loadHabits();
  }

  Future<void> logProgress(String habitId, int value) async {
    if (value <= 0) {
      return;
    }

    final habit = habitById(habitId);
    if (habit == null) {
      return;
    }

    final log = HabitLog(
      id: _uuid.v4(),
      habitId: habitId,
      value: value,
      date: DateTime.now(),
      isManualEntry: true,
    );
    await _dbService.insertLog(log);

    final updatedProgress = progressForDate(
      habit,
      DateTime.now(),
      extraLogs: [log],
    );
    final completed = updatedProgress >= habit.targetValue;
    final nextStreak =
        completed ? _computeUpdatedStreak(habit) : habit.currentStreak;

    final updatedHabit = habit.copyWith(
      currentStreak: nextStreak,
      bestStreak: max(habit.bestStreak, nextStreak),
      lastCompletedDate: completed ? DateTime.now() : habit.lastCompletedDate,
    );

    await _dbService.updateHabit(updatedHabit);
    await _reloadHabits(showLoadingIndicator: false);
  }

  Future<void> quickLog(Habit habit) async {
    if (!canManualLogHabit(habit)) {
      return;
    }

    if (_isWaterHabit(habit)) {
      await logProgress(habit.id, 1);
      return;
    }

    final current = progressForToday(habit);
    final remaining = max(0, habit.targetValue - current);
    final increment = remaining == 0
        ? max(1, habit.targetValue ~/ 4)
        : max(1, min(remaining, max(1, habit.targetValue ~/ 3)));
    await logProgress(habit.id, increment);
  }

  Future<void> setProgressForToday(Habit habit, int value) async {
    final sanitizedValue = max(0, value);
    final now = DateTime.now();
    final wasCompleted = progressForDate(habit, now) >= habit.targetValue;

    final replacementLogs = sanitizedValue == 0
        ? const <HabitLog>[]
        : <HabitLog>[
            HabitLog(
              id: _uuid.v4(),
              habitId: habit.id,
              value: sanitizedValue,
              date: now,
              isManualEntry: true,
            ),
          ];

    if (isStepHabit(habit)) {
      await _dbService.replaceManualLogsForHabitOnDate(
        habitId: habit.id,
        date: now,
        logsForDate: replacementLogs,
      );
      final automaticValue = automaticProgressForHabitOnDate(habit, now);
      await _updateHabitCompletionState(
        habit,
        date: now,
        wasCompleted: wasCompleted,
        effectiveProgress: max(sanitizedValue, automaticValue),
      );
    } else {
      await _dbService.replaceLogsForHabitOnDate(
        habitId: habit.id,
        date: now,
        logsForDate: replacementLogs,
      );
      await _updateHabitCompletionState(
        habit,
        date: now,
        wasCompleted: wasCompleted,
        effectiveProgress: sanitizedValue,
      );
    }

    await _reloadHabits(showLoadingIndicator: false);
  }

  bool isStepHabit(Habit habit) => isStepBasedHabit(habit);
  bool canManualLogHabit(Habit habit) =>
      !isStepHabit(habit) || habit.manualLoggingEnabled;

  String? completionMoodForToday(Habit habit) {
    return _completionMoods['${_dateKey(DateTime.now())}::${habit.id}'];
  }

  Future<void> saveCompletionMoodForToday(Habit habit, String mood) async {
    await _dbService.saveCompletionMood(
      habitId: habit.id,
      date: DateTime.now(),
      mood: mood,
    );
    _completionMoods = {
      ..._completionMoods,
      '${_dateKey(DateTime.now())}::${habit.id}': mood,
    };
    notifyListeners();
  }

  bool _isWaterHabit(Habit habit) {
    return resolvedHabitCategoryId(habit) == 'water';
  }

  int manualProgressForHabitOnDate(Habit habit, DateTime date) {
    return manualProgressForDate(logsForHabit(habit.id), date);
  }

  int automaticProgressForHabitOnDate(Habit habit, DateTime date) {
    return automaticProgressForDate(logsForHabit(habit.id), date);
  }

  bool hasAutomaticSyncToday(Habit habit) {
    return automaticProgressForHabitOnDate(habit, DateTime.now()) > 0;
  }

  String stepStatusLabel(Habit habit) {
    if (!isStepHabit(habit)) {
      return '';
    }

    final automaticSteps =
        automaticProgressForHabitOnDate(habit, DateTime.now());
    if (automaticSteps > 0) {
      return 'Synced from ${_healthSyncSnapshot.sourceLabel}';
    }
    if (_healthSyncSnapshot.connected) {
      return 'Ready to sync';
    }
    return 'Manual fallback';
  }

  String routineWindowLabel(Habit habit) {
    if (habit.reminderTime != null) {
      return _windowLabelForHour(habit.reminderTime!.hour);
    }

    final cue = habit.cue.trim().toLowerCase();
    if (cue.isEmpty) {
      return 'Anytime';
    }
    if (cue.contains('wake') ||
        cue.contains('morning') ||
        cue.contains('breakfast')) {
      return 'Morning';
    }
    if (cue.contains('lunch') ||
        cue.contains('afternoon') ||
        cue.contains('midday')) {
      return 'Afternoon';
    }
    if (cue.contains('dinner') ||
        cue.contains('evening') ||
        cue.contains('bed') ||
        cue.contains('night')) {
      return 'Evening';
    }
    if (cue.contains('free moment') || cue.contains('notice')) {
      return 'Anytime';
    }
    return 'Anytime';
  }

  Future<HealthSyncSnapshot> validateHealthSyncDevice() async {
    final snapshot = await _healthSyncService.validateDevice(
      previous: _healthSyncSnapshot,
    );
    _healthSyncSnapshot = snapshot;
    await _dbService.saveHealthSyncSnapshot(snapshot);
    notifyListeners();
    return snapshot;
  }

  Future<bool> installHealthConnect() {
    return _healthSyncService.installHealthConnect();
  }

  Future<StepSyncResult> connectAndSyncSteps() async {
    final result = await _healthSyncService.connectAndSync(
      previous: _healthSyncSnapshot,
    );
    await _applyStepSyncResult(result);
    return result;
  }

  Future<void> disconnectHealthSync() async {
    final snapshot = await _healthSyncService.disconnect(
      previous: _healthSyncSnapshot,
    );
    _healthSyncSnapshot = snapshot;
    await _dbService.saveHealthSyncSnapshot(snapshot);
    notifyListeners();
  }

  Future<void> acceptAdaptiveSuggestion(Habit habit) async {
    final suggestion = suggestedTarget(habit);
    await _dbService.insertAdaptiveGoalEntry(
      AdaptiveGoalEntry(
        id: _uuid.v4(),
        habitId: habit.id,
        oldTarget: habit.targetValue,
        suggestedTarget: suggestion,
        createdAt: DateTime.now(),
        status: 'accepted',
      ),
    );
    await updateHabit(habit.copyWith(targetValue: suggestion));
  }

  Future<void> keepAdaptiveSuggestion(Habit habit) async {
    final suggestion = suggestedTarget(habit);
    await _dbService.insertAdaptiveGoalEntry(
      AdaptiveGoalEntry(
        id: _uuid.v4(),
        habitId: habit.id,
        oldTarget: habit.targetValue,
        suggestedTarget: suggestion,
        createdAt: DateTime.now(),
        status: 'kept',
      ),
    );
    await loadHabits();
  }

  Future<void> rejectAdaptiveSuggestion(Habit habit) async {
    final suggestion = suggestedTarget(habit);
    await _dbService.insertAdaptiveGoalEntry(
      AdaptiveGoalEntry(
        id: _uuid.v4(),
        habitId: habit.id,
        oldTarget: habit.targetValue,
        suggestedTarget: suggestion,
        createdAt: DateTime.now(),
        status: 'rejected',
      ),
    );
    await loadHabits();
  }

  Habit? habitById(String id) {
    for (final habit in _habits) {
      if (habit.id == id) {
        return habit;
      }
    }
    return null;
  }

  int progressForToday(Habit habit) {
    return progressForDate(habit, DateTime.now());
  }

  int progressForDate(
    Habit habit,
    DateTime date, {
    List<HabitLog> extraLogs = const [],
  }) {
    final logs = [...logsForHabit(habit.id), ...extraLogs];
    return max(0, effectiveProgressForDate(habit, logs, date));
  }

  double progressRatioForDate(Habit habit, DateTime date) {
    if (habit.targetValue <= 0) {
      return 0;
    }
    return (progressForDate(habit, date) / habit.targetValue).clamp(0, 1);
  }

  double progressRatioForToday(Habit habit) {
    return progressRatioForDate(habit, DateTime.now());
  }

  bool isCompletedToday(Habit habit) {
    return progressForToday(habit) >= habit.targetValue;
  }

  int get completedTodayCount {
    return _habits.where(isCompletedToday).length;
  }

  double get overallProgressToday {
    if (_habits.isEmpty) {
      return 0;
    }

    final total = _habits.fold<double>(
      0,
      (sum, habit) => sum + progressRatioForToday(habit),
    );
    return total / _habits.length;
  }

  int remainingForToday(Habit habit) {
    return max(0, habit.targetValue - progressForToday(habit));
  }

  int completionDaysLast7(Habit habit) {
    return List<int>.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return progressForDate(habit, date) >= habit.targetValue ? 1 : 0;
    }).fold<int>(0, (sum, value) => sum + value);
  }

  List<double> last7RatiosForHabit(Habit habit) {
    return List<double>.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return progressRatioForDate(habit, date);
    });
  }

  List<double> last30OverallRatios() {
    return List<double>.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      if (_habits.isEmpty) {
        return 0;
      }

      final total = _habits.fold<double>(
        0,
        (sum, habit) => sum + progressRatioForDate(habit, date),
      );
      return total / _habits.length;
    });
  }

  double automaticityScore(Habit habit) {
    final recentAverage = last7RatiosForHabit(habit).fold<double>(
          0,
          (sum, ratio) => sum + ratio,
        ) /
        7;
    return (recentAverage * 70 + min(habit.currentStreak, 30)).clamp(0, 100);
  }

  int unlockedBadgesCount() {
    var total = 0;
    if (_habits.any((habit) => habit.bestStreak >= 7)) {
      total++;
    }
    if (_habits.any((habit) => habit.bestStreak >= 14)) {
      total++;
    }
    if (_habits.any((habit) => habit.targetValue >= 10000)) {
      total++;
    }
    return total;
  }

  double completionPercentageLast7Days() {
    if (_habits.isEmpty) {
      return 0;
    }

    final ratios = List<double>.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final total = _habits.fold<double>(
        0,
        (sum, habit) => sum + progressRatioForDate(habit, date),
      );
      return total / _habits.length;
    });

    return (ratios.fold<double>(0, (sum, ratio) => sum + ratio) / ratios.length)
        .clamp(0, 1);
  }

  int bestOverallStreak() {
    if (_habits.isEmpty) {
      return 0;
    }
    return _habits.fold<int>(
      0,
      (best, habit) => max(best, max(habit.bestStreak, habit.currentStreak)),
    );
  }

  Habit? mostConsistentHabit() {
    if (_habits.isEmpty) {
      return null;
    }

    Habit? bestHabit;
    double bestScore = -1;
    for (final habit in _habits) {
      final score = averageRatioForHabit(habit);
      if (score > bestScore) {
        bestScore = score;
        bestHabit = habit;
      }
    }
    return bestHabit;
  }

  String weeklyMotivationalFeedback() {
    final completion = completionPercentageLast7Days();
    if (_habits.isEmpty) {
      return 'Start with one small habit and let Momentum build from there.';
    }
    if (completion >= 0.85) {
      return 'Excellent week. Your routines are looking steady and sustainable.';
    }
    if (completion >= 0.6) {
      return 'Solid progress. A little consistency next week will push this even higher.';
    }
    if (completion >= 0.35) {
      return 'You are building momentum. Keep the cues simple and make the next step easy.';
    }
    return 'This week was a reset, not a failure. Shrink the habit and restart with the cue.';
  }

  int cueStrengthScore(Habit habit) {
    final cueBonus = habit.cue.trim().isEmpty ? 0 : 28;
    final consistencyBonus = (averageRatioForHabit(habit) * 52).round();
    final streakBonus = min(habit.currentStreak, 10) * 2;
    return (cueBonus + consistencyBonus + streakBonus).clamp(0, 100);
  }

  String cueStrengthLabel(Habit habit) {
    final score = cueStrengthScore(habit);
    if (score >= 75) {
      return 'Strong cue';
    }
    if (score >= 50) {
      return 'Developing cue';
    }
    return 'Cue needs support';
  }

  String bestWindowOverall() {
    final counts = <String, int>{};
    for (final habitLogs in _logsByHabit.values) {
      for (final log in habitLogs) {
        final window = _windowForHour(log.date.hour);
        counts[window] = (counts[window] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return 'No pattern yet';
    }
    return counts.entries.reduce((left, right) {
      return left.value >= right.value ? left : right;
    }).key;
  }

  String bestWindowForHabit(Habit habit) {
    final logs = logsForHabit(habit.id);
    if (logs.isEmpty) {
      return 'No pattern yet';
    }

    final counts = <String, int>{};
    for (final log in logs) {
      final window = _windowForHour(log.date.hour);
      counts[window] = (counts[window] ?? 0) + 1;
    }
    return counts.entries.reduce((left, right) {
      return left.value >= right.value ? left : right;
    }).key;
  }

  Habit? bestCueHabit() {
    final withCue =
        _habits.where((habit) => habit.cue.trim().isNotEmpty).toList();
    if (withCue.isEmpty) {
      return null;
    }

    Habit? bestHabit;
    double bestScore = -1;
    for (final habit in withCue) {
      final score =
          averageRatioForHabit(habit) + (completionDaysLast7(habit) / 14);
      if (score > bestScore) {
        bestScore = score;
        bestHabit = habit;
      }
    }
    return bestHabit;
  }

  String todayPatternSummary() {
    if (_habits.isEmpty) {
      return 'Add one habit and Momentum will start detecting your strongest routine pattern.';
    }

    final cueHabit = bestCueHabit();
    final bestWindow = bestWindowOverall();
    if (cueHabit != null && bestWindow != 'No pattern yet') {
      return '${cueHabit.name} is strongest when it follows "${cueHabit.cue}" in the $bestWindow.';
    }
    if (cueHabit != null) {
      return '${cueHabit.name} already has a reliable cue in "${cueHabit.cue}". Momentum is still learning the best completion window.';
    }
    if (bestWindow != 'No pattern yet') {
      return 'Your strongest completion window is the $bestWindow. Add clearer cues to lock that pattern in.';
    }
    return 'Momentum is still learning your routine. A few more logs will reveal your strongest pattern.';
  }

  String habitInsightSummary(Habit habit) {
    final completions = completionDaysLast7(habit);
    final cue = habit.cue.trim();
    final bestWindow = bestWindowForHabit(habit);

    if (cue.isEmpty) {
      return 'Add a clear cue to make ${habit.name.toLowerCase()} easier to remember.';
    }
    if (completions >= 5) {
      return '$habit.name works best when anchored to "$cue", especially in the $bestWindow.';
    }
    if (bestWindow == 'No pattern yet') {
      return 'Momentum is still learning when "$cue" works best for ${habit.name.toLowerCase()}.';
    }
    return 'Try protecting your $bestWindow cue for ${habit.name.toLowerCase()} so the routine feels easier to repeat.';
  }

  List<String> overallBehaviorInsights() {
    if (_habits.isEmpty) {
      return const [
        'Start one cue-based habit and Momentum will begin learning your routine patterns.',
      ];
    }

    final insights = <String>[];
    final bestHabit = mostConsistentHabit();
    if (bestHabit != null) {
      insights.add(
        '${bestHabit.name} is currently your most reliable routine at ${(averageRatioForHabit(bestHabit) * 100).round()}% completion.',
      );
    }

    final bestWindow = bestWindowOverall();
    if (bestWindow != 'No pattern yet') {
      insights.add(
        'Your logs are strongest in the $bestWindow, which is a good window for reminders and cue protection.',
      );
    }

    final cueGaps = _habits.where((habit) => habit.cue.trim().isEmpty).length;
    if (cueGaps > 0) {
      insights.add(
        '$cueGaps habit${cueGaps == 1 ? '' : 's'} still have no cue. Adding a trigger usually improves recall and consistency.',
      );
    }

    final adaptiveCount = adaptiveDecisionsCount();
    if (adaptiveCount > 0) {
      insights.add(
        '$adaptiveCount adaptive goal decision${adaptiveCount == 1 ? '' : 's'} have been recorded, which keeps changes visible and user-approved.',
      );
    }

    return insights.take(3).toList();
  }

  int totalLogsCount() {
    return _logsByHabit.values.fold<int>(
      0,
      (sum, habitLogs) => sum + habitLogs.length,
    );
  }

  int adaptiveDecisionsCount() {
    return _adaptiveHistoryByHabit.values.fold<int>(
      0,
      (sum, entries) => sum + entries.length,
    );
  }

  String researchModeSummary() {
    return '${_habits.length} habits, ${totalLogsCount()} progress logs, and ${adaptiveDecisionsCount()} adaptive decisions are available locally for export.';
  }

  double overallAutomaticityScore() {
    if (_habits.isEmpty) {
      return 0;
    }
    final total = _habits.fold<double>(
      0,
      (sum, habit) => sum + automaticityScore(habit),
    );
    return total / _habits.length;
  }

  List<AdaptiveGoalEntry> allAdaptiveGoalEntries() {
    final entries = _adaptiveHistoryByHabit.values
        .expand((items) => items)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(entries);
  }

  String buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('HABITS');
    buffer.writeln(
      'habit_id,habit_name,target,unit,frequency,cue,streak,best_streak,last_completed',
    );
    for (final habit in _habits) {
      buffer.writeln(
        [
          habit.id,
          _escape(habit.name),
          habit.targetValue,
          _escape(habit.unit),
          _escape(habit.frequency),
          _escape(habit.cue),
          habit.currentStreak,
          habit.bestStreak,
          habit.lastCompletedDate?.toIso8601String() ?? '',
        ].join(','),
      );
    }

    buffer.writeln();
    buffer.writeln('LOGS');
    buffer.writeln('log_id,habit_id,value,date,time_window,entry_source');
    for (final habitLogs in _logsByHabit.values) {
      for (final log in habitLogs) {
        buffer.writeln(
          [
            log.id,
            log.habitId,
            log.value,
            log.date.toIso8601String(),
            _escape(_windowForHour(log.date.hour)),
            _escape(log.isManualEntry ? 'manual' : 'device_sync'),
          ].join(','),
        );
      }
    }

    buffer.writeln();
    buffer.writeln('ADAPTIVE_HISTORY');
    buffer.writeln(
      'entry_id,habit_id,old_target,suggested_target,status,created_at',
    );
    for (final entries in _adaptiveHistoryByHabit.values) {
      for (final entry in entries) {
        buffer.writeln(
          [
            entry.id,
            entry.habitId,
            entry.oldTarget,
            entry.suggestedTarget,
            _escape(entry.status),
            entry.createdAt.toIso8601String(),
          ].join(','),
        );
      }
    }

    buffer.writeln();
    buffer.writeln('HEALTH_SYNC');
    buffer.writeln(
      'connected,availability,permission_state,source,last_synced_at,last_synced_steps,last_error',
    );
    buffer.writeln(
      [
        _healthSyncSnapshot.connected,
        _escape(_healthSyncSnapshot.availability),
        _escape(_healthSyncSnapshot.permissionState),
        _escape(_healthSyncSnapshot.sourceLabel),
        _healthSyncSnapshot.lastSyncedAt?.toIso8601String() ?? '',
        _healthSyncSnapshot.lastSyncedSteps ?? '',
        _escape(_healthSyncSnapshot.lastError ?? ''),
      ].join(','),
    );

    return buffer.toString();
  }

  double averageRatioForHabit(Habit habit) {
    final ratios = last7RatiosForHabit(habit);
    return ratios.fold<double>(0, (sum, ratio) => sum + ratio) / ratios.length;
  }

  int suggestedTarget(Habit habit) {
    return max(habit.targetValue + 1, (habit.targetValue * 1.13).round());
  }

  int _computeUpdatedStreak(Habit habit) {
    return _computeUpdatedStreakForDate(habit, DateTime.now());
  }

  int _computeUpdatedStreakForDate(Habit habit, DateTime date) {
    final lastDone = habit.lastCompletedDate;
    if (lastDone == null) {
      return 1;
    }

    final today = date;
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final lastDateOnly = DateTime(lastDone.year, lastDone.month, lastDone.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (lastDateOnly == todayOnly) {
      return habit.currentStreak;
    }
    if (lastDateOnly == yesterday) {
      return habit.currentStreak + 1;
    }
    return 1;
  }

  Future<void> _applyStepSyncResult(StepSyncResult result) async {
    _healthSyncSnapshot = result.snapshot;
    await _dbService.saveHealthSyncSnapshot(_healthSyncSnapshot);

    if (result.success && result.syncedHistory != null) {
      final normalizedHistory = Map<DateTime, int>.from(result.syncedHistory!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if ((normalizedHistory[today] ?? 0) <= 0 &&
          (result.syncedSteps ?? 0) > 0) {
        normalizedHistory[today] = result.syncedSteps!;
      }
      await _applySyncedStepHistory(normalizedHistory);
      return;
    }

    if (result.success && result.syncedSteps != null) {
      await _applySyncedStepsToToday(result.syncedSteps!);
      return;
    }

    notifyListeners();
  }

  Map<DateTime, int> stepHistoryForRecentDays({
    int days = 30,
  }) {
    final stepHabits = _habits.where(isStepHabit).toList();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final history = <DateTime, int>{};

    for (var offset = days - 1; offset >= 0; offset--) {
      final date = normalizedToday.subtract(Duration(days: offset));
      var bestValue = 0;
      for (final habit in stepHabits) {
        bestValue =
            max(bestValue, automaticProgressForHabitOnDate(habit, date));
      }
      history[date] = bestValue;
    }

    final syncedAt = _healthSyncSnapshot.lastSyncedAt;
    final syncedSteps = _healthSyncSnapshot.lastSyncedSteps ?? 0;
    if (syncedAt != null && syncedSteps > 0) {
      final syncedDay = DateTime(syncedAt.year, syncedAt.month, syncedAt.day);
      if (history.containsKey(syncedDay) && (history[syncedDay] ?? 0) <= 0) {
        history[syncedDay] = syncedSteps;
      }
    }

    return history;
  }

  Future<void> _applySyncedStepsToToday(int steps) async {
    final now = DateTime.now();
    final stepHabits = _habits.where(isStepHabit).toList();

    for (final habit in stepHabits) {
      final syncedLogs = steps <= 0
          ? const <HabitLog>[]
          : <HabitLog>[
              HabitLog(
                id: syncedStepLogIdForDate(habit.id, now),
                habitId: habit.id,
                value: steps,
                date: now,
                isManualEntry: false,
              ),
            ];

      await _dbService.replaceAutomaticLogsForHabitOnDate(
        habitId: habit.id,
        date: now,
        logsForDate: syncedLogs,
      );

      final manualValue = manualProgressForHabitOnDate(habit, now);
      await _updateHabitCompletionState(
        habit,
        date: now,
        wasCompleted: progressForDate(habit, now) >= habit.targetValue,
        effectiveProgress: max(manualValue, steps),
      );
    }

    await loadHabits();
  }

  Future<void> _applySyncedStepHistory(Map<DateTime, int> history) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySteps = history[today] ?? 0;
    final stepHabits = _habits.where(isStepHabit).toList();

    for (final habit in stepHabits) {
      for (final entry in history.entries) {
        final date = DateTime(entry.key.year, entry.key.month, entry.key.day);
        final steps = entry.value;
        final syncedLogs = steps <= 0
            ? const <HabitLog>[]
            : <HabitLog>[
                HabitLog(
                  id: syncedStepLogIdForDate(habit.id, date),
                  habitId: habit.id,
                  value: steps,
                  date: date,
                  isManualEntry: false,
                ),
              ];

        await _dbService.replaceAutomaticLogsForHabitOnDate(
          habitId: habit.id,
          date: date,
          logsForDate: syncedLogs,
        );
      }

      final manualToday = manualProgressForHabitOnDate(habit, now);
      await _updateHabitCompletionState(
        habit,
        date: now,
        wasCompleted: progressForDate(habit, now) >= habit.targetValue,
        effectiveProgress: max(manualToday, todaySteps),
      );
    }

    await loadHabits();
  }

  Future<void> _updateHabitCompletionState(
    Habit habit, {
    required DateTime date,
    required bool wasCompleted,
    required int effectiveProgress,
  }) async {
    final completedNow = effectiveProgress >= habit.targetValue;
    final completedDate = DateTime(date.year, date.month, date.day);
    final yesterdayDate = completedDate.subtract(const Duration(days: 1));

    int nextStreak = habit.currentStreak;
    DateTime? lastCompletedDate = habit.lastCompletedDate;

    if (completedNow) {
      nextStreak = wasCompleted
          ? habit.currentStreak
          : _computeUpdatedStreakForDate(habit, date);
      lastCompletedDate = date;
    } else if (wasCompleted &&
        lastCompletedDate != null &&
        _isSameDay(lastCompletedDate, date)) {
      nextStreak = max(0, habit.currentStreak - 1);
      lastCompletedDate = nextStreak > 0 ? yesterdayDate : null;
    }

    final updatedHabit = habit.copyWith(
      currentStreak: nextStreak,
      bestStreak: max(habit.bestStreak, nextStreak),
      lastCompletedDate: lastCompletedDate,
    );

    await _dbService.updateHabit(updatedHabit);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _windowForHour(int hour) {
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 17) {
      return 'afternoon';
    }
    if (hour < 21) {
      return 'evening';
    }
    return 'before bed';
  }

  String _windowLabelForHour(int hour) {
    if (hour < 12) {
      return 'Morning';
    }
    if (hour < 17) {
      return 'Afternoon';
    }
    if (hour < 22) {
      return 'Evening';
    }
    return 'Anytime';
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _escape(String value) {
    final normalized = value.replaceAll('"', '""');
    return '"$normalized"';
  }
}
