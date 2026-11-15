import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Logs the failure [message] of [logName] with [error]. A debug build also
/// prints it, because `dart:developer`'s log stays out of the device log.
void logFailure(
  String message,
  String logName,
  Object error,
  StackTrace stackTrace,
) {
  log(message, name: logName, error: error, stackTrace: stackTrace);
  if (kDebugMode) debugPrint('$logName: $message $error');
}
