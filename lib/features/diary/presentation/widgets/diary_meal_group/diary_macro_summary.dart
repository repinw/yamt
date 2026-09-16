import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One-line `P · C · F` gram summary, colored per macro.
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
    final accents = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final separator = TextSpan(
      text: ' · ',
      style: baseStyle?.copyWith(color: theme.colorScheme.outlineVariant),
    );

    TextSpan macro(String letter, double grams, Color color) => TextSpan(
      text: '$letter ${format.format(grams)}${l10n.caloriesUnitGram}',
      style: baseStyle?.copyWith(color: color),
    );

    return Text.rich(
      TextSpan(
        children: [
          macro(l10n.caloriesProteinShortLetter, protein, accents.protein),
          separator,
          macro(l10n.caloriesCarbsShortLetter, carbs, accents.carbs),
          separator,
          macro(l10n.caloriesFatShortLetter, fat, accents.fat),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
