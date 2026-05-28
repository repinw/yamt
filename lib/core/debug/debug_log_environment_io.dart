import 'dart:io';

/// Whether debug logs should be suppressed for this process.
bool get shouldSuppressDebugLogs {
  return const bool.fromEnvironment('FLUTTER_TEST') ||
      Platform.environment['FLUTTER_TEST'] == 'true';
}
