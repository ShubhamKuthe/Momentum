import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/adaptive_goal_entry.dart';
import '../models/habit.dart';
import '../models/health_sync_snapshot.dart';
import '../models/habit_log.dart';
import '../models/report_file_entry.dart';

class DatabaseService {
  static const _habitsKey = 'momentum.habits';
  static const _logsKey = 'momentum.logs';
  static const _adaptiveHistoryKey = 'momentum.adaptiveHistory';
  static const _signedInKey = 'momentum.signedIn';
  static const _activeUserScopeKey = 'momentum.activeUserScope';
  static const _legacyMigrationCompleteKey = 'momentum.legacyMigrationComplete';
  static const _userNameKey = 'momentum.userName';
  static const _userEmailKey = 'momentum.userEmail';
  static const _userPasswordKey = 'momentum.userPassword';
  static const _userAvatarKey = 'momentum.userAvatar';
  static const _userGenderKey = 'momentum.userGender';
  static const _userDobKey = 'momentum.userDob';
  static const _userStartDateKey = 'momentum.userStartDate';
  static const _onboardingCompleteKey = 'momentum.onboardingComplete';
  static const _onboardingGoalTypeKey = 'momentum.onboardingGoalType';
  static const _onboardingAnswersKey = 'momentum.onboardingAnswers';
  static const _reminderPermissionKey = 'momentum.reminderPermissionState';
  static const _healthSyncStateKey = 'momentum.healthSyncState';
  static const _healthSyncConnectedKey = 'momentum.healthSyncConnected';
  static const _completionMoodKey = 'momentum.completionMood';
  static const _reportFilesKey = 'momentum.reportFiles';

  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  static const List<String> _scopedBaseKeys = <String>[
    _habitsKey,
    _logsKey,
    _adaptiveHistoryKey,
    _userNameKey,
    _userEmailKey,
    _userPasswordKey,
    _userAvatarKey,
    _userGenderKey,
    _userDobKey,
    _userStartDateKey,
    _onboardingCompleteKey,
    _onboardingGoalTypeKey,
    _onboardingAnswersKey,
    _healthSyncStateKey,
    _healthSyncConnectedKey,
    _reminderPermissionKey,
    _completionMoodKey,
    _reportFilesKey,
  ];

  String _normalizedScope(String email) {
    return email.trim().toLowerCase();
  }

  Future<void> clearUserDataForEmail(String email) async {
    final prefs = await _prefs;
    final scope = _normalizedScope(email);
    if (scope.isEmpty) {
      return;
    }

    for (final baseKey in _scopedBaseKeys) {
      await prefs.remove(_scopedKey(baseKey, scope));
    }

    final activeScope = prefs.getString(_activeUserScopeKey)?.trim() ?? '';
    if (activeScope == scope) {
      await prefs.remove(_activeUserScopeKey);
    }
  }

  String _scopedKey(String baseKey, String scope) {
    return '$baseKey::$scope';
  }

  String _resolvedScopedKey(SharedPreferences prefs, String baseKey) {
    final scope = prefs.getString(_activeUserScopeKey)?.trim() ?? '';
    if (scope.isEmpty) {
      return baseKey;
    }
    return _scopedKey(baseKey, scope);
  }

  Future<void> _ensureScopedMigration(
    SharedPreferences prefs, {
    required String nextEmail,
  }) async {
    if (prefs.getBool(_legacyMigrationCompleteKey) ?? false) {
      return;
    }

    final nextScope = _normalizedScope(nextEmail);
    if (nextScope.isEmpty) {
      return;
    }

    final legacyEmail = (prefs.getString(_userEmailKey) ?? '')
        .trim()
        .toLowerCase();
    final migrationScope = legacyEmail.isNotEmpty ? legacyEmail : nextScope;

    for (final baseKey in _scopedBaseKeys) {
      if (!prefs.containsKey(baseKey)) {
        continue;
      }
      final targetKey = _scopedKey(baseKey, migrationScope);
      if (prefs.containsKey(targetKey)) {
        continue;
      }

      final value = prefs.get(baseKey);
      if (value is String) {
        await prefs.setString(targetKey, value);
      } else if (value is bool) {
        await prefs.setBool(targetKey, value);
      } else if (value is int) {
        await prefs.setInt(targetKey, value);
      } else if (value is double) {
        await prefs.setDouble(targetKey, value);
      } else if (value is List<String>) {
        await prefs.setStringList(targetKey, value);
      }
    }

    await prefs.setBool(_legacyMigrationCompleteKey, true);
  }

  Future<bool> getOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_resolvedScopedKey(prefs, _onboardingCompleteKey)) ??
        false;
  }

  Future<bool> getSignedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_signedInKey) ?? false;
  }

  Future<void> setSignedIn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_signedInKey, value);
  }

  Future<String> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _userNameKey)) ?? '';
  }

  Future<String> getUserEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _userEmailKey)) ?? '';
  }

  Future<String> getUserPassword() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _userPasswordKey)) ?? '';
  }

  Future<String> getUserAvatar() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _userAvatarKey)) ?? '';
  }

  Future<String> getUserGender() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _userGenderKey)) ?? '';
  }

  Future<DateTime?> getUserDob() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _userDobKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<DateTime?> getUserStartDate() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _userStartDateKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> saveUserIdentity({
    required String name,
    required String email,
    String? password,
  }) async {
    final prefs = await _prefs;
    await _ensureScopedMigration(prefs, nextEmail: email);
    final scope = _normalizedScope(email);
    await prefs.setString(_activeUserScopeKey, scope);
    await prefs.setString(_scopedKey(_userNameKey, scope), name);
    await prefs.setString(_scopedKey(_userEmailKey, scope), email);
    if (password != null && password.isNotEmpty) {
      await prefs.setString(_scopedKey(_userPasswordKey, scope), password);
    }
    final startDateKey = _scopedKey(_userStartDateKey, scope);
    if (!(prefs.containsKey(startDateKey))) {
      await prefs.setString(startDateKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> saveUserGender(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_resolvedScopedKey(prefs, _userGenderKey), value);
  }

  Future<void> saveUserDob(DateTime? value) async {
    final prefs = await _prefs;
    final key = _resolvedScopedKey(prefs, _userDobKey);
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.toIso8601String());
  }

  Future<void> saveUserPassword(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_resolvedScopedKey(prefs, _userPasswordKey), value);
  }

  Future<void> saveUserAvatar(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_resolvedScopedKey(prefs, _userAvatarKey), value);
  }

  Future<void> clearUserAvatar() async {
    final prefs = await _prefs;
    await prefs.remove(_resolvedScopedKey(prefs, _userAvatarKey));
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(
      _resolvedScopedKey(prefs, _onboardingCompleteKey),
      value,
    );
  }

  Future<String> getOnboardingGoalType() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _onboardingGoalTypeKey)) ??
        'steps';
  }

  Future<void> setOnboardingGoalType(String value) async {
    final prefs = await _prefs;
    await prefs.setString(
      _resolvedScopedKey(prefs, _onboardingGoalTypeKey),
      value,
    );
  }

  Future<Map<String, dynamic>> getOnboardingAnswers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(
      _resolvedScopedKey(prefs, _onboardingAnswersKey),
    );
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> setOnboardingAnswers(Map<String, dynamic> value) async {
    final prefs = await _prefs;
    await prefs.setString(
      _resolvedScopedKey(prefs, _onboardingAnswersKey),
      jsonEncode(value),
    );
  }

  Future<String> getReminderPermissionState() async {
    final prefs = await _prefs;
    return prefs.getString(_resolvedScopedKey(prefs, _reminderPermissionKey)) ??
        'not_requested';
  }

  Future<void> setReminderPermissionState(String value) async {
    final prefs = await _prefs;
    await prefs.setString(
      _resolvedScopedKey(prefs, _reminderPermissionKey),
      value,
    );
  }

  Future<Map<String, String>> getCompletionMoodMap() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _completionMoodKey));
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveCompletionMood({
    required String habitId,
    required DateTime date,
    required String mood,
  }) async {
    final prefs = await _prefs;
    final current = await getCompletionMoodMap();
    current['${_dateKey(date)}::$habitId'] = mood;
    await prefs.setString(
      _resolvedScopedKey(prefs, _completionMoodKey),
      jsonEncode(current),
    );
  }

  Future<List<ReportFileEntry>> getReportFiles() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _reportFilesKey));
    if (raw == null || raw.isEmpty) {
      return <ReportFileEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final files = decoded
        .map(
          (item) =>
              ReportFileEntry.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .where((entry) => entry.path.trim().isNotEmpty)
        .toList();
    files.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return files;
  }

  Future<void> saveReportFile(ReportFileEntry entry) async {
    final prefs = await _prefs;
    final entries = await getReportFiles();
    entries.removeWhere((item) => item.path == entry.path);
    entries.insert(0, entry);
    await prefs.setString(
      _resolvedScopedKey(prefs, _reportFilesKey),
      jsonEncode(entries.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> removeReportFile(String path) async {
    final prefs = await _prefs;
    final entries = await getReportFiles()
      ..removeWhere((entry) => entry.path == path);
    await prefs.setString(
      _resolvedScopedKey(prefs, _reportFilesKey),
      jsonEncode(entries.map((item) => item.toMap()).toList()),
    );
  }

  Future<HealthSyncSnapshot> getHealthSyncSnapshot() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _healthSyncStateKey));
    if (raw != null && raw.isNotEmpty) {
      return HealthSyncSnapshot.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    }

    final legacyConnected =
        prefs.getBool(_resolvedScopedKey(prefs, _healthSyncConnectedKey)) ??
        false;
    return HealthSyncSnapshot.initial().copyWith(connected: legacyConnected);
  }

  Future<void> saveHealthSyncSnapshot(HealthSyncSnapshot snapshot) async {
    final prefs = await _prefs;
    await prefs.setString(
      _resolvedScopedKey(prefs, _healthSyncStateKey),
      jsonEncode(snapshot.toMap()),
    );
    await prefs.setBool(
      _resolvedScopedKey(prefs, _healthSyncConnectedKey),
      snapshot.connected,
    );
  }

  Future<bool> getHealthSyncConnected() async {
    final snapshot = await getHealthSyncSnapshot();
    return snapshot.connected;
  }

  Future<void> setHealthSyncConnected(bool value) async {
    final snapshot = await getHealthSyncSnapshot();
    await saveHealthSyncSnapshot(snapshot.copyWith(connected: value));
  }

  Future<void> insertHabit(Habit habit) async {
    final habits = await getHabits();
    final updated = [...habits];
    final index = updated.indexWhere((item) => item.id == habit.id);
    if (index == -1) {
      updated.add(habit);
    } else {
      updated[index] = habit;
    }
    await _writeHabits(updated);
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _habitsKey));
    if (raw == null || raw.isEmpty) {
      return <Habit>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final habits = decoded
        .map((item) => Habit.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
    habits.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return habits;
  }

  Future<void> updateHabit(Habit habit) async {
    await insertHabit(habit);
  }

  Future<void> deleteHabit(String id) async {
    final habits = await getHabits();
    await _writeHabits(habits.where((habit) => habit.id != id).toList());

    final logs = await _readLogs();
    logs.removeWhere((log) => log.habitId == id);
    await _writeLogs(logs);

    final prefs = await _prefs;
    final moods = await getCompletionMoodMap();
    moods.removeWhere((key, value) => key.endsWith('::$id'));
    await prefs.setString(
      _resolvedScopedKey(prefs, _completionMoodKey),
      jsonEncode(moods),
    );
  }

  Future<void> insertLog(HabitLog log) async {
    final logs = await _readLogs();
    logs.removeWhere((item) => item.id == log.id);
    logs.add(log);
    await _writeLogs(logs);
  }

  Future<void> replaceLogsForHabitOnDate({
    required String habitId,
    required DateTime date,
    required List<HabitLog> logsForDate,
  }) async {
    final logs = await _readLogs();
    logs.removeWhere(
      (log) => log.habitId == habitId && _isSameDay(log.date, date),
    );
    logs.addAll(logsForDate);
    await _writeLogs(logs);
  }

  Future<void> replaceManualLogsForHabitOnDate({
    required String habitId,
    required DateTime date,
    required List<HabitLog> logsForDate,
  }) async {
    final logs = await _readLogs();
    logs.removeWhere(
      (log) =>
          log.habitId == habitId &&
          _isSameDay(log.date, date) &&
          log.isManualEntry,
    );
    logs.addAll(logsForDate.where((log) => log.isManualEntry));
    await _writeLogs(logs);
  }

  Future<void> replaceAutomaticLogsForHabitOnDate({
    required String habitId,
    required DateTime date,
    required List<HabitLog> logsForDate,
  }) async {
    final logs = await _readLogs();
    logs.removeWhere(
      (log) =>
          log.habitId == habitId &&
          _isSameDay(log.date, date) &&
          !log.isManualEntry,
    );
    logs.addAll(logsForDate.where((log) => !log.isManualEntry));
    await _writeLogs(logs);
  }

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    final logs = await _readLogs();
    return logs.where((log) => log.habitId == habitId).toList()
      ..sort((left, right) => right.date.compareTo(left.date));
  }

  Future<void> insertAdaptiveGoalEntry(AdaptiveGoalEntry entry) async {
    final entries = await getAdaptiveGoalEntries();
    entries.removeWhere((item) => item.id == entry.id);
    entries.add(entry);
    await _writeAdaptiveGoalEntries(entries);
  }

  Future<List<AdaptiveGoalEntry>> getAdaptiveGoalEntries() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _adaptiveHistoryKey));
    if (raw == null || raw.isEmpty) {
      return <AdaptiveGoalEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries = decoded
        .map(
          (item) =>
              AdaptiveGoalEntry.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    entries.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return entries;
  }

  Future<void> _writeHabits(List<Habit> habits) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(habits.map((habit) => habit.toMap()).toList());
    await prefs.setString(_resolvedScopedKey(prefs, _habitsKey), encoded);
  }

  Future<List<HabitLog>> _readLogs() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resolvedScopedKey(prefs, _logsKey));
    if (raw == null || raw.isEmpty) {
      return <HabitLog>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HabitLog.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _writeLogs(List<HabitLog> logs) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(logs.map((log) => log.toMap()).toList());
    await prefs.setString(_resolvedScopedKey(prefs, _logsKey), encoded);
  }

  Future<void> _writeAdaptiveGoalEntries(
    List<AdaptiveGoalEntry> entries,
  ) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(entries.map((entry) => entry.toMap()).toList());
    await prefs.setString(
      _resolvedScopedKey(prefs, _adaptiveHistoryKey),
      encoded,
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
