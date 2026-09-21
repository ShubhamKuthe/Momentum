class AdaptiveGoalEntry {
  const AdaptiveGoalEntry({
    required this.id,
    required this.habitId,
    required this.oldTarget,
    required this.suggestedTarget,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String habitId;
  final int oldTarget;
  final int suggestedTarget;
  final DateTime createdAt;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'oldTarget': oldTarget,
      'suggestedTarget': suggestedTarget,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory AdaptiveGoalEntry.fromMap(Map<String, dynamic> map) {
    return AdaptiveGoalEntry(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      oldTarget: map['oldTarget'] as int,
      suggestedTarget: map['suggestedTarget'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: map['status'] as String,
    );
  }
}
