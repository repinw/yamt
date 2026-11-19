import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One-line `P · C · F` gram summary in muted text; only the numbers carry
/// the fixed macro colors, whatever "Makros immer bunt" says.
class DiaryMacroSummary extends StatelessWidget {
  /// Creates a macro summary.
  const new({
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
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final accents = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final macros = [
      (l10n.caloriesProteinShortLetter, protein, accents.protein),
      (l10n.caloriesCarbsShortLetter, carbs, accents.carbs),
      (l10n.caloriesFatShortLetter, fat, accents.fat),
    ];

    return Text.rich(
      TextSpan(
        children: [
          for (final (index, (letter, grams, color)) in macros.indexed) ...[
            if (index > 0) const TextSpan(text: ' · '),
            TextSpan(text: '$letter '),
            TextSpan(
              text: format.format(grams),
              style: style?.copyWith(color: color),
            ),
            TextSpan(text: l10n.caloriesUnitGram),
          ],
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
