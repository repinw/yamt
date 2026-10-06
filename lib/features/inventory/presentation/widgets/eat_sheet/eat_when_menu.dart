import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Small top-right control for the day and meal of a food log.
///
/// Shows "TODAY · SNACK" and opens a menu with the meal types and a date
/// picker from 2000 up to [today], or up to the last day that can be planned
/// when [allowsPlanDays] is set, for a page whose save plans a later day.
class EatWhenMenu extends StatelessWidget {
  /// Creates the day and meal control.
  const new({
    required this.loggedAt,
    required this.today,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.onDayPicked,
    this.allowsPlanDays = false,
    super.key,
  });

  /// Key of the button that opens the menu.
  static const buttonKey = Key('eat_page_when_button');

  /// Key of the menu entry that opens the date picker.
  static const pickDayKey = Key('eat_page_when_pick_day');

  static final _firstSelectableDay = DateTime(2000);

  /// When the food is logged.
  final DateTime loggedAt;

  /// The current day.
  final DateTime today;

  /// Selected meal.
  final MealType mealType;

  /// Called with another meal.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Called with the picked day at date-only precision.
  final ValueChanged<DateTime> onDayPicked;

  /// Whether days after [today] can be picked, because the page saves them
  /// as plans.
  final bool allowsPlanDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final day = isSameCalendarDay(loggedAt, today)
        ? l10n.caloriesTodayAction
        : MaterialLocalizations.of(context).formatShortMonthDay(loggedAt);
    final label = l10n.eatPageWhen(day, mealType.localizedName(l10n));

    return PopupMenuButton<Object>(
      key: buttonKey,
      tooltip: label,
      color: colors.card,
      onSelected: (choice) {
        switch (choice) {
          case final MealType type:
            onMealTypeChanged(type);
          case _:
            unawaited(_pickDay(context));
        }
      },
      itemBuilder: (context) => [
        for (final type in MealType.sectionOrder)
          CheckedPopupMenuItem<Object>(
            value: type,
            checked: type == mealType,
            child: Text(type.localizedName(l10n)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          key: pickDayKey,
          value: _PickDay.choice,
          child: Text(l10n.eatPagePickDay),
        ),
      ],
      // A round pill on the tile surface, inside a 48 pixel tap target.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tile,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppFoodLabel.chip),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xxs,
                  children: [
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: AppFoodLabel.navLabelTracking,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: colors.ink),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final lastDay = allowsPlanDays ? _lastPlanDay(today) : dateOnly(today);
    final loggedDay = dateOnly(loggedAt);
    final picked = await showDatePicker(
      context: context,
      initialDate: loggedDay.isAfter(lastDay) ? lastDay : loggedDay,
      firstDate: _firstSelectableDay,
      lastDate: lastDay,
    );
    if (picked != null) {
      onDayPicked(dateOnly(picked));
    }
  }
}

/// Asks for the day to plan on: today or one of the days after it that can
/// be planned. Returns the day at date-only precision, or null.
Future<DateTime?> showEatPlanDayPicker(
  BuildContext context, {
  required DateTime today,
  required DateTime loggedAt,
}) async {
  final firstDay = dateOnly(today);
  final lastDay = _lastPlanDay(today);
  final loggedDay = dateOnly(loggedAt);
  final picked = await showDatePicker(
    context: context,
    initialDate: loggedDay.isBefore(firstDay)
        ? firstDay
        : loggedDay.isAfter(lastDay)
        ? lastDay
        : loggedDay,
    firstDate: firstDay,
    lastDate: lastDay,
  );
  return picked == null ? null : dateOnly(picked);
}

DateTime _lastPlanDay(DateTime today) {
  final day = dateOnly(today);
  return DateTime(day.year, day.month, day.day + diaryPlanAheadDayCount);
}

/// Menu entry that opens the date picker.
enum _PickDay { choice }
