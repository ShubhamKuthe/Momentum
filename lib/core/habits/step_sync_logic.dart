import '../../models/habit.dart';
import '../../models/habit_log.dart';

bool isStepBasedHabit(Habit habit) {
  final normalizedCategory = (habit.categoryId ?? '').toLowerCase();
  final normalizedName = habit.name.toLowerCase();
  final normalizedUnit = habit.unit.toLowerCase();

  final usesStepUnit = _usesStepUnit(normalizedUnit);
  final explicitStepName = normalizedName.contains('step');

  return usesStepUnit ||
      explicitStepName ||
      (normalizedCategory == 'steps' && usesStepUnit);
}

int manualProgressForDate(
  Iterable<HabitLog> logs,
  DateTime date,
) {
  return _progressForDate(
    logs.where((log) => log.isManualEntry),
    date,
  );
}

int automaticProgressForDate(
  Iterable<HabitLog> logs,
  DateTime date,
) {
  return _progressForDate(
    logs.where((log) => !log.isManualEntry),
    date,
  );
}

int effectiveProgressForDate(
  Habit habit,
  Iterable<HabitLog> logs,
  DateTime date,
) {
  if (!isStepBasedHabit(habit)) {
    return _progressForDate(
      logs.where((log) => log.isManualEntry),
      date,
    );
  }

  final manual = manualProgressForDate(logs, date);
  final automatic = automaticProgressForDate(logs, date);
  return manual >= automatic ? manual : automatic;
}

String syncedStepLogIdForDate(String habitId, DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'sync-$habitId-$year$month$day';
}

int _progressForDate(
  Iterable<HabitLog> logs,
  DateTime date,
) {
  return logs
      .where((log) => _isSameDay(log.date, date))
      .fold<int>(0, (sum, log) => sum + log.value);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _usesStepUnit(String normalizedUnit) {
  return normalizedUnit.contains('step');
}
