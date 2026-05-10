import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Formats the logged day label for calorie entry detail controls.
String calorieEntryLoggedDayLabel(
  AppLocalizations l10n,
  MaterialLocalizations material,
  DateTime loggedAt,
) {
  if (DateUtils.isSameDay(loggedAt, DateTime.now())) {
    return l10n.caloriesTodayAction;
  }
  return material.formatShortDate(loggedAt);
}

/// Formats the logged day and time label for calorie entry details.
String calorieEntryLoggedAtMetaLabel(
  BuildContext context,
  AppLocalizations l10n,
  MaterialLocalizations material,
  DateTime loggedAt,
) {
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(loggedAt),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${calorieEntryLoggedDayLabel(l10n, material, loggedAt)}, $timeLabel';
}

/// Formats the consumed amount label for the calorie entry details header.
String calorieEntryConsumedAmountLabel(
  AppLocalizations l10n,
  CalorieEntry entry,
) {
  if (entry.isBundle) {
    return l10n.caloriesBundlePortions(
      formatPreparedMealPortions(
        entry.bundleConsumedPortions ?? 0,
        localeName: l10n.localeName,
      ),
      entry.bundleTotalPortions ?? 0,
    );
  }

  return '${formatCalorieEntryNutritionMetricValue(entry.consumedAmount)} '
      '${entry.consumedUnit.localizedName(l10n)}';
}

/// Formats a nutrition metric without trailing decimals when possible.
String formatCalorieEntryNutritionMetricValue(double value) {
  final hasFraction = value % 1 != 0;
  return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
