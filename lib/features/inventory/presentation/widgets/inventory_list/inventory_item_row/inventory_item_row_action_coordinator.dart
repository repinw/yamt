import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

const _coordinatorLogName = 'InventoryItemRowActionCoordinator';

class InventoryItemRowActionCoordinator {
  const InventoryItemRowActionCoordinator({
    required this.isWorking,
    required this.setWorking,
    required this.isMounted,
    required this.showSnackBar,
    required this.defaultFailureMessage,
  });

  final bool Function() isWorking;
  final void Function(bool isWorking) setWorking;
  final bool Function() isMounted;
  final void Function(String message) showSnackBar;
  final String defaultFailureMessage;

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
