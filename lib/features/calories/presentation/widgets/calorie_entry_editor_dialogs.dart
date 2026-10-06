import 'package:material_ui/material_ui.dart';

/// Pick a new date for loggedAt value.
Future<DateTime?> showCalorieEntryDatePicker(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
}

/// Pick a new time for loggedAt value.
Future<TimeOfDay?> showCalorieEntryTimePicker(
  BuildContext context, {
  required DateTime initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialTime),
  );
}
