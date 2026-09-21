import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/health_sync_snapshot.dart';

class StepSyncResult {
  const StepSyncResult({
    required this.success,
    required this.message,
    required this.snapshot,
    this.syncedSteps,
    this.syncedHistory,
  });

  final bool success;
  final String message;
  final HealthSyncSnapshot snapshot;
  final int? syncedSteps;
  final Map<DateTime, int>? syncedHistory;
}

class HealthSyncService {
  HealthSyncService._();

  static final HealthSyncService instance = HealthSyncService._();

  final Health _health = Health();
  bool _configured = false;

  Future<void> initialize() async {
    if (_configured || kIsWeb || !_supportsHealthSync) {
      return;
    }

    await _health.configure();
    _configured = true;
  }

  Future<HealthSyncSnapshot> validateDevice({
    HealthSyncSnapshot? previous,
  }) async {
    final base = previous ?? HealthSyncSnapshot.initial();
    final sourceLabel = _sourceLabel;

    if (kIsWeb || !_supportsHealthSync) {
      return base.copyWith(
        connected: false,
        availability: 'unsupported',
        sourceLabel: sourceLabel,
        permissionState: 'unsupported',
        lastError: 'Step sync is only available on Android and iPhone.',
      );
    }

    try {
      await initialize();

      var availability = _platform == TargetPlatform.iOS ? 'available' : 'unknown';
      if (_platform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        availability = _androidAvailabilityFromStatus(status?.name ?? '');
      }

      var permissionState = base.permissionState;
      if (availability == 'available') {
        final hasPermission = await _health.hasPermissions(
              const [HealthDataType.STEPS],
              permissions: const [HealthDataAccess.READ],
            ) ??
            false;
        permissionState = hasPermission ? 'granted' : 'not_requested';
      }

      return base.copyWith(
        availability: availability,
        sourceLabel: sourceLabel,
        permissionState: permissionState,
        clearLastError: true,
      );
    } catch (error) {
      return base.copyWith(
        availability: 'unsupported',
        sourceLabel: sourceLabel,
        connected: false,
        lastError: error.toString(),
      );
    }
  }

  Future<bool> installHealthConnect() async {
    if (_platform != TargetPlatform.android) {
      return false;
    }

    await initialize();
    await _health.installHealthConnect();
    return true;
  }

  Future<StepSyncResult> connectAndSync({
    HealthSyncSnapshot? previous,
  }) async {
    final validated = await validateDevice(previous: previous);
    if (!validated.isAvailable) {
      return StepSyncResult(
        success: false,
        message: validated.availability == 'needs_install'
            ? 'Install Health Connect first to enable real step sync.'
            : 'This device does not currently support real step sync.',
        snapshot: validated.copyWith(connected: false),
      );
    }

    if (_platform == TargetPlatform.android) {
      final activityPermission = await Permission.activityRecognition.request();
      if (!activityPermission.isGranted) {
        final snapshot = validated.copyWith(
          connected: false,
          permissionState: 'denied',
          lastError: 'Activity recognition permission is required for steps.',
        );
        return StepSyncResult(
          success: false,
          message: 'Allow activity recognition to sync real steps.',
          snapshot: snapshot,
        );
      }
    }

    try {
      await initialize();

      final granted = await _health.requestAuthorization(
        const [HealthDataType.STEPS],
        permissions: const [HealthDataAccess.READ],
      );

      if (!granted) {
        final snapshot = validated.copyWith(
          connected: false,
          permissionState: 'denied',
          lastError: 'Health data access was not granted.',
        );
        return StepSyncResult(
          success: false,
          message: 'Health permission was denied.',
          snapshot: snapshot,
        );
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(
            midnight,
            now,
            includeManualEntry: false,
          ) ??
          0;
      final history = await _loadStepHistory(days: 30);

      final snapshot = validated.copyWith(
        connected: true,
        permissionState: 'granted',
        lastSyncedAt: now,
        lastSyncedSteps: steps,
        clearLastError: true,
      );

      return StepSyncResult(
        success: true,
        message: 'Real steps and recent history synced from ${snapshot.sourceLabel}.',
        snapshot: snapshot,
        syncedSteps: steps,
        syncedHistory: history,
      );
    } catch (error) {
      final snapshot = validated.copyWith(
        connected: false,
        lastError: error.toString(),
      );
      return StepSyncResult(
        success: false,
        message: 'Could not sync steps on this device.',
        snapshot: snapshot,
      );
    }
  }

  Future<StepSyncResult> refreshConnectedSteps({
    HealthSyncSnapshot? previous,
  }) async {
    final validated = await validateDevice(previous: previous);
    if (!validated.connected && previous?.connected != true) {
      return StepSyncResult(
        success: false,
        message: 'Health sync is not connected yet.',
        snapshot: validated,
      );
    }

    if (validated.permissionState != 'granted') {
      return StepSyncResult(
        success: false,
        message: 'Health permission is no longer granted.',
        snapshot: validated.copyWith(
          connected: false,
          lastError: 'Health permission must be granted before refreshing synced steps.',
        ),
      );
    }

    if (!validated.isAvailable) {
      return StepSyncResult(
        success: false,
        message: 'This device cannot refresh step sync right now.',
        snapshot: validated.copyWith(connected: false),
      );
    }

    try {
      await initialize();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(
            midnight,
            now,
            includeManualEntry: false,
          ) ??
          0;
      final history = await _loadStepHistory(days: 30);

      final snapshot = validated.copyWith(
        connected: true,
        lastSyncedAt: now,
        lastSyncedSteps: steps,
        clearLastError: true,
      );

      return StepSyncResult(
        success: true,
        message: 'Synced latest steps and recent history from ${snapshot.sourceLabel}.',
        snapshot: snapshot,
        syncedSteps: steps,
        syncedHistory: history,
      );
    } catch (error) {
      final snapshot = validated.copyWith(
        lastError: error.toString(),
      );
      return StepSyncResult(
        success: false,
        message: 'Could not refresh synced steps.',
        snapshot: snapshot,
      );
    }
  }

  Future<HealthSyncSnapshot> disconnect({
    HealthSyncSnapshot? previous,
  }) async {
    final snapshot = previous ?? HealthSyncSnapshot.initial();
    return snapshot.copyWith(
      connected: false,
      clearLastError: true,
    );
  }

  bool get _supportsHealthSync =>
      _platform == TargetPlatform.android || _platform == TargetPlatform.iOS;

  String get _sourceLabel {
    if (_platform == TargetPlatform.iOS) {
      return 'Apple Health';
    }
    if (_platform == TargetPlatform.android) {
      return 'Google Health via Health Connect';
    }
    return 'Device';
  }

  TargetPlatform get _platform => defaultTargetPlatform;

  Future<Map<DateTime, int>> _loadStepHistory({
    int days = 30,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final history = <DateTime, int>{};

    for (var offset = days - 1; offset >= 0; offset--) {
      final dayStart = today.subtract(Duration(days: offset));
      final dayEnd = offset == 0 ? now : dayStart.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(
            dayStart,
            dayEnd,
            includeManualEntry: false,
          ) ??
          0;
      history[dayStart] = steps;
    }

    return history;
  }

  String _androidAvailabilityFromStatus(String statusName) {
    final normalized = statusName.toLowerCase();
    if (normalized.contains('available')) {
      return 'available';
    }
    if (normalized.contains('install')) {
      return 'needs_install';
    }
    if (normalized.contains('update')) {
      return 'needs_install';
    }
    if (normalized.contains('unavailable') || normalized.contains('unsupported')) {
      return 'unsupported';
    }
    return 'unknown';
  }
}
