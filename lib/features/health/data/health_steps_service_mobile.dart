import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_steps_service.dart';

const _stepTypes = <HealthDataType>[HealthDataType.STEPS];
const _stepPermissions = <HealthDataAccess>[HealthDataAccess.READ];

/// Create health steps service.
HealthStepsService createHealthStepsService() {
  return MobileHealthStepsService();
}

/// Reads steps through the health plugin.
class MobileHealthStepsService implements HealthStepsService {
  /// Creates an instance.
  new({Health? health, bool? isAndroid})
    : _health = health ?? Health(),
      _isAndroid = isAndroid ?? Platform.isAndroid;

  final Health _health;
  final bool _isAndroid;
  bool _isConfigured = false;

  @override
  Future<bool> requestAccess() async {
    await _ensureConfigured();
    final answered = await _health.requestAuthorization(
      _stepTypes,
      permissions: _stepPermissions,
    );
    // Health Connect also answers true when other permissions were granted
    // before, so it checks the steps themselves.
    return _isAndroid ? await _hasAndroidAccess() : answered;
  }

  @override
  Future<int?> loadSteps({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    await _ensureConfigured();
    // Apple Health hides a missing permission and answers 0 steps.
    if (_isAndroid && !await _hasAndroidAccess()) {
      return null;
    }
    return await _health.getTotalStepsInInterval(startInclusive, endExclusive);
  }

  Future<bool> _hasAndroidAccess() async =>
      await _health.hasPermissions(_stepTypes, permissions: _stepPermissions) ==
      true;

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }
}
