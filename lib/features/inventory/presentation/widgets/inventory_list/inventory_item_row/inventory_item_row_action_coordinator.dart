import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';

const _coordinatorLogName = 'InventoryItemRowActionCoordinator';

/// Defines inventory item row action coordinator.
class InventoryItemRowActionCoordinator {
  /// The inventory item row action coordinator.
  const new({
    required this.isWorking,
    required this.setWorking,
    required this.isMounted,
    required this.showSnackBar,
    required this.defaultFailureMessage,
  });

  /// Whether working.
  final bool Function() isWorking;

  /// The set working.
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isWorking) setWorking;

  /// Whether mounted.
  final bool Function() isMounted;

  /// Shows the action result.
  ///
  /// A non-null undo adds the undo action to the snack bar.
  final void Function(
    String message,
    AppSnackBarTone tone,
    Future<bool> Function()? undo,
  )
  showSnackBar;

  /// The default failure message.
  final String defaultFailureMessage;

  /// Runs [action] and shows its result. [undo] reverts a successful action
  /// from the success snack bar.
  Future<void> runAction(
    Future<bool> Function() action, {
    String? successMessage,
    String? failureMessage,
    Future<bool> Function()? undo,
  }) async {
    if (isWorking() || !isMounted()) {
      return;
    }

    setWorking(true);
    var success = false;
    try {
      success = await action();
    } on Object catch (error, stackTrace) {
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
        showSnackBar(successMessage, AppSnackBarTone.success, undo);
      }
      return;
    }

    showSnackBar(
      failureMessage ?? defaultFailureMessage,
      AppSnackBarTone.error,
      null,
    );
  }
}
