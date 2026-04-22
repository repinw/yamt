import 'package:flutter/material.dart';

/// Defines calorie goal start picker.
abstract final class CalorieGoalStartPicker {
  /// Pick date.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialGoalStartDate,
    DateTime? now,
  }) async {
    final referenceDate = normalizeDate(now ?? DateTime.now());
    final normalizedInitialDate = normalizeDate(initialGoalStartDate);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: normalizedInitialDate.isAfter(referenceDate)
          ? referenceDate
          : normalizedInitialDate,
      firstDate: DateTime(referenceDate.year - 10),
      lastDate: referenceDate,
    );
    if (!context.mounted) {
      return null;
    }
    return pickedDate == null ? null : normalizeDate(pickedDate);
  }

  /// Normalize date.
  static DateTime normalizeDate(DateTime value) {
    return DateUtils.dateOnly(value);
  }

  /// Whether same day.
  static bool isSameDay(DateTime left, DateTime right) {
    return DateUtils.isSameDay(left, right);
  }
}
