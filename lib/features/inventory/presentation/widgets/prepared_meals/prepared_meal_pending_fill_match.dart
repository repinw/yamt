import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_ingredient_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Framed box with the best Vorrat match for an open row, how much of it is
/// left, and the lime "Übernehmen" button.
class PreparedMealPendingFillMatch extends StatelessWidget {
  /// Creates the box for [item].
  const new({
    required this.item,
    required this.takeKey,
    required this.onTake,
    super.key,
  });

  /// The Vorrat match.
  final InventoryItem item;

  /// Key of the "Übernehmen" button.
  final Key takeKey;

  /// Fills the row with [item].
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: colors.rule)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              l10n.preparedMealFillStockMatch.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.preparedMealFillStockLeft(
                    pendingIngredientInventoryAmount(item),
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
              ],
            ),
            FilledButton(
              key: takeKey,
              onPressed: onTake,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: Text(l10n.preparedMealFillTake),
            ),
          ],
        ),
      ),
    );
  }
}
