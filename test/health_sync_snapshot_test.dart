import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/models/health_sync_snapshot.dart';

void main() {
  test('health sync snapshot serializes and restores step sync evidence', () {
    final snapshot = HealthSyncSnapshot(
      connected: true,
      permissionState: 'granted',
      availability: 'available',
      sourceLabel: 'Health Connect',
      lastSyncedSteps: 4218,
      lastSyncedAt: DateTime(2026, 7, 16, 14, 30),
      lastError: null,
    );

    final restored = HealthSyncSnapshot.fromMap(snapshot.toMap());

    expect(restored.connected, isTrue);
    expect(restored.permissionState, 'granted');
    expect(restored.availability, 'available');
    expect(restored.sourceLabel, 'Health Connect');
    expect(restored.lastSyncedSteps, 4218);
    expect(restored.lastSyncedAt, DateTime(2026, 7, 16, 14, 30));
    expect(restored.lastError, isNull);
  });
}
