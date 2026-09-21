import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _persistentFollowUpCount = 6;
  static const Duration _persistentFollowUpInterval = Duration(minutes: 20);
  static const String _logoAssetPath = 'assets/images/notification_logo.png';
  static const String _androidSmallIcon = 'app_icon';
  static const AndroidNotificationChannel _habitChannel =
      AndroidNotificationChannel(
    'momentum_habit_reminders',
    'Habit reminders',
    description: 'Cue-based reminders for Momentum habits',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _testChannel =
      AndroidNotificationChannel(
    'momentum_test_reminders',
    'Test reminders',
    description: 'Preview reminders for Momentum habits',
    importance: Importance.max,
  );

  bool _initialized = false;
  AndroidBitmap<Object>? _androidLargeIcon;

  bool get _supportsNotifications => !kIsWeb;

  Future<void> initialize() async {
    if (_initialized || !_supportsNotifications) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = AndroidInitializationSettings(_androidSmallIcon);
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open Momentum',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Momentum',
      appUserModelId: 'uk.ac.liverpool.comp702.momentum',
      guid: '5d765d1d-53aa-4d9d-9f75-9c5a13cf0017',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notifications.initialize(settings);
    await _createAndroidChannels();
    await _loadNotificationAssets();
    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_habitChannel);
    await android?.createNotificationChannel(_testChannel);
  }

  Future<void> _loadNotificationAssets() async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        _androidLargeIcon != null) {
      return;
    }

    try {
      final byteData = await rootBundle.load(_logoAssetPath);
      _androidLargeIcon = ByteArrayAndroidBitmap(
        byteData.buffer.asUint8List(),
      );
    } catch (_) {
      _androidLargeIcon = null;
    }
  }

  Future<bool> requestPermission() async {
    if (!_supportsNotifications) {
      return false;
    }

    await initialize();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      case TargetPlatform.macOS:
        final macos = _notifications.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        return await macos?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }

  Future<bool?> areNotificationsEnabled() async {
    if (!_supportsNotifications) {
      return false;
    }

    await initialize();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled();
      default:
        return null;
    }
  }

  Future<void> syncAllHabits(
    List<Habit> habits, {
    required bool Function(Habit habit) isCompletedToday,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    for (final habit in habits) {
      await syncHabitReminder(
        habit,
        completedToday: isCompletedToday(habit),
      );
    }
  }

  Future<void> syncHabitReminder(
    Habit habit, {
    bool completedToday = false,
  }) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    await _cancelAllScheduledIds(habit.id);

    if (habit.reminderTime == null) {
      return;
    }

    final nextReminder = _nextOccurrence(
      habit.reminderTime!,
      skipToday: completedToday,
    );

    await _scheduleDailyBaseReminder(habit, nextReminder);

    if (habit.reminderMode == 'persistent') {
      await _schedulePersistentFollowUps(habit, nextReminder);
    }
  }

  Future<void> _scheduleDailyBaseReminder(
    Habit habit,
    tz.TZDateTime scheduledFor,
  ) async {
    await _notifications.zonedSchedule(
      _notificationIdForHabitSlot(habit.id, 0),
      'Momentum reminder',
      _habitReminderBody(habit),
      scheduledFor,
      _notificationDetailsFor(habit),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: habit.id,
    );
  }

  Future<void> _schedulePersistentFollowUps(
    Habit habit,
    tz.TZDateTime firstReminder,
  ) async {
    for (var index = 1; index <= _persistentFollowUpCount; index++) {
      final scheduledFor =
          firstReminder.add(_persistentFollowUpInterval * index);

      await _notifications.zonedSchedule(
        _notificationIdForHabitSlot(habit.id, index),
        'Momentum reminder',
        _persistentFollowUpBody(habit, index),
        scheduledFor,
        _notificationDetailsFor(habit),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: habit.id,
      );
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    await _cancelAllScheduledIds(habitId);
  }

  Future<bool> showTestReminder(Habit habit) async {
    if (!_supportsNotifications) {
      return false;
    }

    await initialize();
    final enabled = await areNotificationsEnabled();
    if (enabled == false) {
      return false;
    }
    await _notifications.show(
      _notificationIdForHabitSlot(habit.id, 999),
      'Momentum test reminder',
      _habitReminderBody(habit),
      _notificationDetailsFor(habit, isTest: true),
      payload: habit.id,
    );
    return true;
  }

  NotificationDetails _notificationDetailsFor(
    Habit habit, {
    bool isTest = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isTest ? 'momentum_test_reminders' : 'momentum_habit_reminders',
        isTest ? 'Test reminders' : 'Habit reminders',
        channelDescription: isTest
            ? 'Preview reminders for Momentum habits'
            : 'Cue-based reminders for Momentum habits',
        icon: _androidSmallIcon,
        largeIcon: _androidLargeIcon,
        importance: habit.reminderMode == 'persistent'
            ? Importance.max
            : Importance.high,
        priority:
            habit.reminderMode == 'persistent' ? Priority.max : Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: habit.reminderMode != 'vibrate',
        enableVibration: true,
        ongoing: habit.reminderMode == 'persistent' && !isTest,
        autoCancel: habit.reminderMode != 'persistent' || isTest,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: habit.reminderMode != 'vibrate',
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: habit.reminderMode != 'vibrate',
      ),
    );
  }

  int _notificationIdForHabit(String habitId) {
    return habitId.codeUnits.fold<int>(
          17,
          (value, code) => (value * 31) + code,
        ) &
        0x7fffffff;
  }

  int _notificationIdForHabitSlot(String habitId, int slot) {
    return ((_notificationIdForHabit(habitId) * 37) + slot) & 0x7fffffff;
  }

  Future<void> _cancelAllScheduledIds(String habitId) async {
    for (var index = 0; index <= _persistentFollowUpCount; index++) {
      await _notifications.cancel(_notificationIdForHabitSlot(habitId, index));
    }
    await _notifications.cancel(_notificationIdForHabitSlot(habitId, 999));
  }

  String _habitReminderBody(Habit habit) {
    if (habit.reminderMode == 'persistent') {
      return 'Keep going until ${habit.name.toLowerCase()} is done.';
    }
    final cue = habit.cue.trim();
    if (cue.isEmpty) {
      return 'Time for ${habit.name.toLowerCase()}.';
    }
    return '${habit.name} - $cue';
  }

  String _persistentFollowUpBody(Habit habit, int index) {
    if (index <= 2) {
      return 'Quick check: finish ${habit.name.toLowerCase()} when you can.';
    }
    return 'Momentum is still waiting for ${habit.name.toLowerCase()}.';
  }

  tz.TZDateTime _nextOccurrence(
    TimeOfDay time, {
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now) || skipToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
