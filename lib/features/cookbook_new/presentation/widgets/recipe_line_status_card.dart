import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where the ingredients of a recipe stand in its cook run: "Noch N offen",
/// "N im Einkauf" or "Alles bereit", whichever applies first, and a line of
/// the counts that are not 0, such as "3 bereit · 1 im Einkauf · 1
/// weggelassen"; a line that does not count in the nutrition is in none of
/// them. Display only.
class RecipeLineStatusCard extends StatelessWidget {
  /// Creates the card for the given counts.
  const new({
    required this.ready,
    required this.shopping,
    required this.ignored,
    required this.open,
    super.key,
  });

  /// Key of the card.
  static const cardKey = ValueKey<String>('recipe-line-status');

  /// Lines with a Vorrat food.
  final int ready;

  /// Lines on the shopping list.
  final int shopping;

  /// Lines the cook leaves out.
  final int ignored;

  /// Lines without an answer yet.
  final int open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = open > 0
        ? l10n.recipeLinesOpenTitle(open)
        : shopping > 0
        ? l10n.recipeLinesShopping(shopping)
        : l10n.recipeLinesReadyTitle;
    final counts = [
      if (ready > 0) l10n.recipeLinesReady(ready),
      if (shopping > 0) l10n.recipeLinesShopping(shopping),
      if (ignored > 0) l10n.recipeLinesIgnored(ignored),
      if (open > 0) l10n.recipeLinesOpen(open),
    ];

    return Semantics(
      key: cardKey,
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(
            color: colors.ink,
            width: AppFoodLabel.chipOutline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (counts.isNotEmpty)
                Text(
                  counts.reduce(l10n.recipeLinesJoined),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
