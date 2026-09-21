import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_picker.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks the user for the end date of a maintain goal.
///
/// The date cannot be earlier than [goalStartDate] or today. Returns null when
/// the user cancels.
Future<DateTime?> pickCalorieMaintainUntil(
  BuildContext context, {
  required DateTime goalStartDate,
  DateTime? current,
}) {
  final now = CalorieGoalStartPicker.normalizeDate(DateTime.now());
  final firstDate = goalStartDate.isAfter(now) ? goalStartDate : now;
  return showDatePicker(
    context: context,
    initialDate: current != null && !current.isBefore(firstDate)
        ? current
        : firstDate,
    firstDate: firstDate,
    lastDate: DateTime(firstDate.year + 50, 12, 31),
  );
}

/// Row that shows and edits the optional end date of a maintain goal.
class CalorieGoalMaintainUntilTile extends StatelessWidget {
  /// Creates the maintain-until tile.
  const new({
    required this.maintainUntil,
    required this.onChoose,
    required this.onClear,
    super.key,
  });

  /// Selected end date, or null when the goal has no end date.
  final DateTime? maintainUntil;

  /// Opens the date picker.
  final VoidCallback onChoose;

  /// Removes the end date.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final until = maintainUntil;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_repeat_rounded),
      title: Text(l10n.caloriesMaintainUntilTitle),
      subtitle: Text(
        until == null
            ? l10n.caloriesMaintainUntilUnlimited
            : MaterialLocalizations.of(context).formatMediumDate(until),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (until != null)
            IconButton(
              tooltip: l10n.caloriesMaintainUntilClear,
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded),
            ),
          IconButton(
            tooltip: l10n.caloriesMaintainUntilChoose,
            onPressed: onChoose,
            icon: const Icon(Icons.edit_calendar_rounded),
          ),
        ],
      ),
    );
  }
}
