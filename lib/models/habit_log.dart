class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.value,
    required this.date,
    this.isManualEntry = true,
  });

  final String id;
  final String habitId;
  final int value;
  final DateTime date;
  final bool isManualEntry;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'value': value,
      'date': date.toIso8601String(),
      'isManualEntry': isManualEntry ? 1 : 0,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      value: map['value'] as int,
      date: DateTime.parse(map['date'] as String),
      isManualEntry: map['isManualEntry'] == 1,
    );
  }
}
