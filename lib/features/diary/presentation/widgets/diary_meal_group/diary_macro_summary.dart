import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One-line `P · C · F` gram summary in muted text.
class DiaryMacroSummary extends StatelessWidget {
  /// Creates a macro summary.
  const DiaryMacroSummary({
    required this.protein,
    required this.carbs,
    required this.fat,
    super.key,
  });

  /// Protein in grams.
  final double protein;

  /// Carbohydrates in grams.
  final double carbs;

  /// Fat in grams.
  final double fat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    String macro(String letter, double grams) =>
        '$letter ${format.format(grams)}${l10n.caloriesUnitGram}';

    return Text(
      [
        macro(l10n.caloriesProteinShortLetter, protein),
        macro(l10n.caloriesCarbsShortLetter, carbs),
        macro(l10n.caloriesFatShortLetter, fat),
      ].join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
