import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/app_field_card.dart';
import 'package:yamt/core/widgets/app_icon_badge.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Day and meal type of a food log, side by side.
///
/// The day card opens a date picker from 2000 up to [today]. It shows only a
/// calendar icon while [loggedAt] is on [today], and the date otherwise.
class MealLogTimeRow extends StatelessWidget {
  /// Creates the day and meal type row.
  const new({
    required this.loggedAt,
    required this.today,
    required this.mealType,
    required this.onDayPicked,
    required this.onMealTypeChanged,
    super.key,
  });

  /// Tap target of the day card.
  static const dayButtonKey = Key('meal_log_time_row_day_button');

  /// Day card content while the log is on today.
  static const dayCompactKey = Key('meal_log_time_row_day_compact');

  /// Day card content while the log is on another day.
  static const dayLabeledKey = Key('meal_log_time_row_day_labeled');

  static final _firstSelectableDay = DateTime(2000);

  /// When the food is logged.
  final DateTime loggedAt;

  /// The current day. Later days cannot be picked.
  final DateTime today;

  /// Selected meal type.
  final MealType mealType;

  /// Called with the picked day at date-only precision.
  final ValueChanged<DateTime> onDayPicked;

  /// Called when the user picks another meal type.
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final isToday = isSameCalendarDay(loggedAt, today);
    final dayCard = _DayCard(
      label: isToday
          ? null
          : MaterialLocalizations.of(context).formatMediumDate(loggedAt),
      onPressed: () => _pickDay(context),
    );

    return Row(
      children: [
        if (isToday) dayCard else Expanded(child: dayCard),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MealTypeCard(
            mealType: mealType,
            onChanged: onMealTypeChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final lastDay = dateOnly(today);
    final loggedDay = dateOnly(loggedAt);
    final pickedDay = await showDatePicker(
      context: context,
      initialDate: loggedDay.isAfter(lastDay) ? lastDay : loggedDay,
      firstDate: _firstSelectableDay,
      lastDate: lastDay,
    );
    if (pickedDay == null) {
      return;
    }
    onDayPicked(dateOnly(pickedDay));
  }
}

class _DayCard extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chevron = Icon(
      Icons.chevron_right_rounded,
      color: colors.onSurfaceVariant,
    );
    const calendarIcon = AppIconBadge(icon: Icons.calendar_today_rounded);
    final text = label;

    return AppFieldCard(
      tapTargetKey: MealLogTimeRow.dayButtonKey,
      onTap: onPressed,
      child: text == null
          ? Row(
              key: MealLogTimeRow.dayCompactKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                calendarIcon,
                const SizedBox(width: AppSpacing.md),
                chevron,
              ],
            )
          : Row(
              key: MealLogTimeRow.dayLabeledKey,
              children: [
                calendarIcon,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                chevron,
              ],
            ),
    );
  }
}

class _MealTypeCard extends StatelessWidget {
  const new({required this.mealType, required this.onChanged});

  final MealType mealType;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return AppFieldCard(
      child: Row(
        children: [
          const AppIconBadge(icon: Icons.restaurant_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<MealType>(
                value: mealType,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                dropdownColor: colors.surfaceContainerHigh,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: colors.onSurfaceVariant,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final type in MealType.sectionOrder)
                    DropdownMenuItem<MealType>(
                      value: type,
                      child: Text(
                        type.localizedName(l10n),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
