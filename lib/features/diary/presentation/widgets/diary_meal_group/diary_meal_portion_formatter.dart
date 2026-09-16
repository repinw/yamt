import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Formats the portion or bundle amount string for a diary meal entry.
String? formatDiaryMealPortionLabel(
  BuildContext context,
  DiaryMealEntry entry,
) {
  final l10n = AppLocalizations.of(context)!;
  if (entry.bundleTotalPortions != null && entry.bundleTotalPortions! > 0) {
    final consumed = entry.bundleConsumedPortions ?? 0;
    final formattedConsumed = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(consumed);
    return l10n.caloriesBundlePortions(
      formattedConsumed,
      entry.bundleTotalPortions!,
    );
  }
  final amount = entry.consumedAmount;
  if (amount == null || amount <= 0) {
    return null;
  }
  final format = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  )..maximumFractionDigits = 1;
  final unit = entry.consumedUnit?.localizedName(l10n) ?? l10n.caloriesUnitGram;
  return '${format.format(amount)} $unit';
}
