/// Result from exporting calorie debug dump.
sealed class CalorieDebugDumpPrintResult {
  const new();
}

/// Successful calorie debug dump export.
class CalorieDebugDumpPrintSuccess extends CalorieDebugDumpPrintResult {
  /// Creates success result.
  const new({required this.rowCount, this.filePath});

  /// Number of rows exported.
  final int rowCount;

  /// Saved path, when the platform exposes one.
  final String? filePath;
}

/// User canceled calorie debug dump export.
class CalorieDebugDumpPrintCanceled extends CalorieDebugDumpPrintResult {
  /// Creates canceled result.
  const new();
}

/// Failed calorie debug dump export.
class CalorieDebugDumpPrintFailure extends CalorieDebugDumpPrintResult {
  /// Creates failure result.
  const new();
}

/// Result from printing calorie settings debug dump.
sealed class CalorieSettingsDebugDumpPrintResult {
  const new();
}

/// Successful calorie settings debug dump print.
class CalorieSettingsDebugDumpPrintSuccess
    extends CalorieSettingsDebugDumpPrintResult {
  /// Creates success result.
  const new({required this.entryCount});

  /// Number of goal-history entries printed.
  final int entryCount;
}

/// Failed calorie settings debug dump print.
class CalorieSettingsDebugDumpPrintFailure
    extends CalorieSettingsDebugDumpPrintResult {
  /// Creates failure result.
  const new();
}

/// Result from printing calorie weekly check-in debug dump.
sealed class CalorieWeeklyCheckInDebugDumpPrintResult {
  const new();
}

/// Successful calorie weekly check-in debug dump print.
class CalorieWeeklyCheckInDebugDumpPrintSuccess
    extends CalorieWeeklyCheckInDebugDumpPrintResult {
  /// Creates success result.
  const new();
}

/// Failed calorie weekly check-in debug dump print.
class CalorieWeeklyCheckInDebugDumpPrintFailure
    extends CalorieWeeklyCheckInDebugDumpPrintResult {
  /// Creates failure result.
  const new();
}
