import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Small top-right control for the day and meal of a food log.
///
/// Shows "TODAY · SNACK" and opens a menu with the meal types and a date
/// picker from 2000 up to [today].
class EatWhenMenu extends StatelessWidget {
  /// Creates the day and meal control.
  const new({
    required this.loggedAt,
    required this.today,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.onDayPicked,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontFamily: AppFonts.mono, color: colors.muted),
            ),
            Icon(Icons.expand_more_rounded, color: colors.muted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final lastDay = dateOnly(today);
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

/// Menu entry that opens the date picker.
enum _PickDay { choice }
