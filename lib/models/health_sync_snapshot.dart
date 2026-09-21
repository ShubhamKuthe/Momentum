class HealthSyncSnapshot {
  const HealthSyncSnapshot({
    required this.connected,
    required this.permissionState,
    required this.availability,
    required this.sourceLabel,
    this.lastSyncedSteps,
    this.lastSyncedAt,
    this.lastError,
  });

  final bool connected;
  final String permissionState;
  final String availability;
  final String sourceLabel;
  final int? lastSyncedSteps;
  final DateTime? lastSyncedAt;
  final String? lastError;

  factory HealthSyncSnapshot.initial() {
    return const HealthSyncSnapshot(
      connected: false,
      permissionState: 'not_requested',
      availability: 'unknown',
      sourceLabel: 'Device',
    );
  }

  factory HealthSyncSnapshot.fromMap(Map<String, dynamic> map) {
    return HealthSyncSnapshot(
      connected: map['connected'] as bool? ?? false,
      permissionState: map['permissionState'] as String? ?? 'not_requested',
      availability: map['availability'] as String? ?? 'unknown',
      sourceLabel: map['sourceLabel'] as String? ?? 'Device',
      lastSyncedSteps: map['lastSyncedSteps'] as int?,
      lastSyncedAt: map['lastSyncedAt'] == null
          ? null
          : DateTime.tryParse(map['lastSyncedAt'] as String),
      lastError: map['lastError'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'connected': connected,
      'permissionState': permissionState,
      'availability': availability,
      'sourceLabel': sourceLabel,
      'lastSyncedSteps': lastSyncedSteps,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  HealthSyncSnapshot copyWith({
    bool? connected,
    String? permissionState,
    String? availability,
    String? sourceLabel,
    int? lastSyncedSteps,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearLastSyncedSteps = false,
    bool clearLastSyncedAt = false,
    bool clearLastError = false,
  }) {
    return HealthSyncSnapshot(
      connected: connected ?? this.connected,
      permissionState: permissionState ?? this.permissionState,
      availability: availability ?? this.availability,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      lastSyncedSteps:
          clearLastSyncedSteps ? null : lastSyncedSteps ?? this.lastSyncedSteps,
      lastSyncedAt:
          clearLastSyncedAt ? null : lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  bool get isAvailable => availability == 'available';
}
