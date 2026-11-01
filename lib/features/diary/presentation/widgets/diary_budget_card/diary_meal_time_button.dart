import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// A time of the parts of the day in words, like "bis 09:00", as a button
/// that opens the time picker.
class DiaryMealTimeButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.minute,
    required this.label,
    required this.onPicked,
    super.key,
  });

  /// Minute of the day it shows.
  final int minute;

  /// Puts the formatted time into words.
  final String Function(String time) label;

  /// Gets the picked minute of the day.
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      onPressed: () => unawaited(
        showTimePicker(context: context, initialTime: time).then((picked) {
          if (picked != null) onPicked(picked.hour * 60 + picked.minute);
        }),
      ),
      child: Text(
        label(
          MaterialLocalizations.of(context).formatTimeOfDay(
            time,
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          ),
        ),
      ),
    );
  }
}
