import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

const _coordinatorLogName = 'InventoryItemRowActionCoordinator';

/// Defines inventory item row action coordinator.
class InventoryItemRowActionCoordinator {
  /// The inventory item row action coordinator.
  const InventoryItemRowActionCoordinator({
    required this.isWorking,
    required this.setWorking,
    required this.isMounted,
    required this.showSnackBar,
    required this.defaultFailureMessage,
  });

  /// Whether working.
  final bool Function() isWorking;

  /// The set working.
  final void Function(bool isWorking) setWorking;

  /// Whether mounted.
  final bool Function() isMounted;

  /// The show snack bar.
  final void Function(String message) showSnackBar;

  /// The default failure message.
  final String defaultFailureMessage;

  /// Creates an instance.
  Future<void> runAction(
    Future<bool> Function() action, {
    String? successMessage,
    String? failureMessage,
  }) async {
    if (isWorking() || !isMounted()) {
      return;
    }

    setWorking(true);
    var success = false;
    try {
      success = await action();
    } catch (error, stackTrace) {
      log(
        'Action failed',
        name: _coordinatorLogName,
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[$_coordinatorLogName] Action failed: $error');
      success = false;
    } finally {
      if (isMounted()) {
        setWorking(false);
      }
    }

    if (!isMounted()) {
      return;
    }

    if (success) {
      if (successMessage != null) {
        showSnackBar(successMessage);
      }
      return;
    }

    showSnackBar(failureMessage ?? defaultFailureMessage);
  }
}
