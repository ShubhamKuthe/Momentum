import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/core/habits/step_sync_logic.dart';
import 'package:momentum/models/habit.dart';
import 'package:momentum/models/habit_log.dart';

void main() {
  final createdAt = DateTime(2026, 7, 16, 8);
  final today = DateTime(2026, 7, 16, 14);

  Habit buildHabit({
    required String name,
    required String unit,
    String? categoryId,
  }) {
    return Habit(
      id: 'habit-1',
      name: name,
      targetValue: 6000,
      unit: unit,
      cue: 'After lunch',
      categoryId: categoryId,
      createdAt: createdAt,
    );
  }

  HabitLog buildLog({
    required String id,
    required int value,
    required bool manual,
  }) {
    return HabitLog(
      id: id,
      habitId: 'habit-1',
      value: value,
      date: today,
      isManualEntry: manual,
    );
  }

  test('step habits use the larger of manual and synced progress', () {
    final habit = buildHabit(
      name: 'Daily Steps',
      unit: 'steps',
      categoryId: 'steps',
    );
    final logs = [
      buildLog(id: 'manual', value: 1800, manual: true),
      buildLog(id: 'sync', value: 4218, manual: false),
    ];

    expect(isStepBasedHabit(habit), isTrue);
    expect(effectiveProgressForDate(habit, logs, today), 4218);
  });

  test('non-step habits still sum all progress logs', () {
    final habit = buildHabit(
      name: 'Workout Session',
      unit: 'min',
      categoryId: 'workout',
    );
    final logs = [
      buildLog(id: 'log-1', value: 10, manual: true),
      buildLog(id: 'log-2', value: 12, manual: true),
    ];

    expect(isStepBasedHabit(habit), isFalse);
    expect(effectiveProgressForDate(habit, logs, today), 22);
  });

  test('synced step log id stays stable for the same day', () {
    expect(
      syncedStepLogIdForDate('steps-habit', DateTime(2026, 7, 16, 9, 30)),
      'sync-steps-habit-20260716',
    );
  });
}
