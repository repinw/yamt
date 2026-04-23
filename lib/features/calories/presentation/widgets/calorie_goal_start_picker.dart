import 'package:flutter/material.dart';

/// Defines calorie goal start picker.
abstract final class CalorieGoalStartPicker {
  /// Pick date.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialGoalStartDate,
    DateTime? now,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final referenceDate = normalizeDate(now ?? DateTime.now());
    final normalizedFirstDate = normalizeDate(
      firstDate ??
          DateTime(
            referenceDate.year - 10,
          ),
    );
    final normalizedLastDate = normalizeDate(
      lastDate ?? DateTime(referenceDate.year + 10, 12, 31),
    );
    final normalizedInitialDate = normalizeDate(initialGoalStartDate);
    final clampedInitialDate =
        normalizedInitialDate.isBefore(
          normalizedFirstDate,
        )
        ? normalizedFirstDate
        : normalizedInitialDate.isAfter(normalizedLastDate)
        ? normalizedLastDate
        : normalizedInitialDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: clampedInitialDate,
      firstDate: normalizedFirstDate,
      lastDate: normalizedLastDate,
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
