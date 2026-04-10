import 'package:flutter/material.dart';

abstract final class CalorieGoalStartPicker {
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialGoalStartAt,
    DateTime? now,
  }) async {
    final referenceNow = roundToMinute(now ?? DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialGoalStartAt,
      firstDate: DateTime(referenceNow.year - 10, 1, 1),
      lastDate: DateTime(referenceNow.year + 10, 12, 31),
    );
    if (!context.mounted) {
      return null;
    }
    return pickedDate;
  }

  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    required DateTime initialGoalStartAt,
  }) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialGoalStartAt),
    );
    if (!context.mounted) {
      return null;
    }
    return pickedTime;
  }

  static DateTime roundToMinute(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  static DateTime combineDateAndTime({
    required DateTime date,
    required TimeOfDay time,
  }) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime sixAm(DateTime date) {
    return DateTime(date.year, date.month, date.day, 6);
  }

  static bool isSameMinute(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day &&
        left.hour == right.hour &&
        left.minute == right.minute;
  }
}
