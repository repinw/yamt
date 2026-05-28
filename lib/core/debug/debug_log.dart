import 'dart:developer' show log;

import 'package:yamt/core/debug/debug_log_environment.dart';

/// Writes a structured application log entry.
void appLog(
  String message, {
  required String name,
  Object? error,
  StackTrace? stackTrace,
}) {
  log(message, name: name, error: error, stackTrace: stackTrace);
}

/// Starts a stopwatch for debug-only timing assertions.
Stopwatch startDebugStopwatch() {
  return Stopwatch()..start();
}

/// Stops a debug stopwatch and returns its elapsed duration.
Duration stopDebugStopwatch(Stopwatch? stopwatch) {
  final activeStopwatch = stopwatch;
  if (activeStopwatch == null) {
    return Duration.zero;
  }
  activeStopwatch.stop();
  return activeStopwatch.elapsed;
}

/// Writes a structured log entry only when Dart assertions are enabled.
void debugLog(
  String message, {
  required String name,
  Object? error,
  StackTrace? stackTrace,
}) {
  assert(() {
    if (shouldSuppressDebugLogs) {
      return true;
    }

    appLog(message, name: name, error: error, stackTrace: stackTrace);
    return true;
  }(), 'debugLog should run only in debug mode.');
}
