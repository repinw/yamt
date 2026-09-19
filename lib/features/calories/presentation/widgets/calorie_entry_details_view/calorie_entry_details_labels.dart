import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
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

/// First brand of the entry, or `null` when it has none.
///
/// Product databases often list the retailer, the maker, and the label in one
/// comma-separated field. The details header shows only the first one.
String? calorieEntryPrimaryBrand(CalorieEntry entry) {
  final brand = entry.brand?.split(',').first.trim();
  return brand == null || brand.isEmpty ? null : brand;
}

/// Formats the consumed amount label for the calorie entry details header.
String calorieEntryConsumedAmountLabel(
  AppLocalizations l10n,
  CalorieEntry entry,
) {
  if (entry.isBundle) {
    return l10n.caloriesBundlePortions(
      _formatBundlePortions(
        entry.bundleConsumedPortions ?? 0,
        localeName: l10n.localeName,
      ),
      entry.bundleTotalPortions ?? 0,
    );
  }

  return '${formatCalorieEntryNutritionMetricValue(entry.consumedAmount)} '
      '${entry.consumedUnit.localizedName(l10n)}';
}

String _formatBundlePortions(num portions, {String? localeName}) {
  return NumberFormat.decimalPattern(localeName).format(portions);
}

/// Formats a nutrition metric without trailing decimals when possible.
String formatCalorieEntryNutritionMetricValue(double value) {
  const displayScale = 10.0;
  final roundedValue = (value * displayScale).roundToDouble() / displayScale;
  final hasFraction = roundedValue != roundedValue.truncateToDouble();
  return hasFraction
      ? roundedValue.toStringAsFixed(1)
      : roundedValue.toStringAsFixed(0);
}
