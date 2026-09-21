import 'package:flutter/material.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.targetValue,
    required this.unit,
    required this.cue,
    this.manualLoggingEnabled = false,
    this.categoryId,
    this.colorValue,
    this.iconKey,
    this.reminderTime,
    this.reminderMode = 'standard',
    this.frequency = 'Daily',
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
    this.lastCompletedDate,
  });

  final String id;
  final String name;
  final int targetValue;
  final String unit;
  final String cue;
  final bool manualLoggingEnabled;
  final String? categoryId;
  final int? colorValue;
  final String? iconKey;
  final TimeOfDay? reminderTime;
  final String reminderMode;
  final String frequency;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;
  final DateTime? lastCompletedDate;

  String get targetLabel => '$targetValue $unit';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetValue': targetValue,
      'unit': unit,
      'cue': cue,
      'manualLoggingEnabled': manualLoggingEnabled,
      'categoryId': categoryId,
      'colorValue': colorValue,
      'iconKey': iconKey,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'reminderMode': reminderMode,
      'frequency': frequency,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'createdAt': createdAt.toIso8601String(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final reminderHour = map['reminderHour'] as int?;
    final reminderMinute = map['reminderMinute'] as int?;

    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      targetValue: map['targetValue'] as int,
      unit: map['unit'] as String,
      cue: map['cue'] as String? ?? '',
      manualLoggingEnabled: map['manualLoggingEnabled'] as bool? ?? false,
      categoryId: map['categoryId'] as String?,
      colorValue: map['colorValue'] as int?,
      iconKey: map['iconKey'] as String?,
      reminderTime: reminderHour == null || reminderMinute == null
          ? null
          : TimeOfDay(hour: reminderHour, minute: reminderMinute),
      reminderMode: map['reminderMode'] as String? ?? 'standard',
      frequency: map['frequency'] as String? ?? 'Daily',
      currentStreak: map['currentStreak'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastCompletedDate: map['lastCompletedDate'] == null
          ? null
          : DateTime.parse(map['lastCompletedDate'] as String),
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    int? targetValue,
    String? unit,
    String? cue,
    bool? manualLoggingEnabled,
    String? categoryId,
    int? colorValue,
    String? iconKey,
    TimeOfDay? reminderTime,
    String? reminderMode,
    bool clearReminder = false,
    String? frequency,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? lastCompletedDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      cue: cue ?? this.cue,
      manualLoggingEnabled: manualLoggingEnabled ?? this.manualLoggingEnabled,
      categoryId: categoryId ?? this.categoryId,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      reminderTime: clearReminder ? null : reminderTime ?? this.reminderTime,
      reminderMode: reminderMode ?? this.reminderMode,
      frequency: frequency ?? this.frequency,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
