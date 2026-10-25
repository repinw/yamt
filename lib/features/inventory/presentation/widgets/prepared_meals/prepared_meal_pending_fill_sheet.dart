import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/barcode_icon.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_match.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_option.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the cook chose to fill an open row with.
sealed class PreparedMealPendingFillChoice {
  const new();
}

/// Use the best Vorrat match with the row's own amount.
final class PreparedMealPendingFillTake extends PreparedMealPendingFillChoice {
  /// Creates the choice for [item].
  const new(this.item);

  /// The Vorrat item.
  final InventoryItem item;
}

/// Pick other Vorrat foods.
final class PreparedMealPendingFillPickStock
    extends PreparedMealPendingFillChoice {
  /// Creates the choice.
  const new();
}

/// Find a new food through [source].
final class PreparedMealPendingFillFind extends PreparedMealPendingFillChoice {
  /// Creates the choice.
  const new(this.source);

  /// Where the food comes from.
  final PreparedMealFoodSource source;
}

/// Put the row on the shopping list; the meal keeps it as it is.
final class PreparedMealPendingFillShoppingList
    extends PreparedMealPendingFillChoice {
  /// Creates the choice.
  const new();
}

/// Leave the row out of the meal.
final class PreparedMealPendingFillIgnore
    extends PreparedMealPendingFillChoice {
  /// Creates the choice.
  const new();
}

/// Bottom sheet that offers the ways to fill the open or ignored row
/// [ingredient]: the best Vorrat match first, then the Vorrat, search,
/// barcode, AI, the shopping list, and ignoring an open row.
class PreparedMealPendingFillSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({
    required this.ingredient,
    required this.match,
    this.canIgnore = true,
    super.key,
  });

  /// Key of the "Übernehmen" button.
  static const takeKey = ValueKey<String>('pending-fill-take');

  /// Key of the option of [source].
  static ValueKey<String> sourceKey(PreparedMealFoodSource source) =>
      ValueKey<String>('pending-fill-${source.name}');

  /// Key of the Vorrat option.
  static const stockKey = ValueKey<String>('pending-fill-stock');

  /// Key of "Auf die Einkaufsliste".
  static const shoppingListKey = ValueKey<String>('pending-fill-shopping-list');

  /// Key of "Zeile ignorieren".
  static const ignoreKey = ValueKey<String>('pending-fill-ignore');

  /// The open row.
  final String ingredient;

  /// The best Vorrat match that can take the row's amount, or `null`.
  final InventoryItem? match;

  /// Whether the sheet offers "Zeile ignorieren"; not for an ignored row.
  final bool canIgnore;

  /// Shows the sheet and returns the choice, or `null` when it is closed.
  static Future<PreparedMealPendingFillChoice?> show(
    BuildContext context, {
    required String ingredient,
    required InventoryItem? match,
    bool canIgnore = true,
  }) {
    return showModalBottomSheet<PreparedMealPendingFillChoice>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => PreparedMealPendingFillSheet(
        ingredient: ingredient,
        match: match,
        canIgnore: canIgnore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final matchItem = match;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(
                  l10n.preparedMealFillTitle.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppGraphit.kickerTracking,
                  ),
                ),
                Text(
                  ingredient,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (matchItem != null)
              PreparedMealPendingFillMatch(
                item: matchItem,
                takeKey: takeKey,
                onTake: () =>
                    Navigator.of(context)
                        .pop(PreparedMealPendingFillTake(matchItem)),
              ),
            Column(
              children: [
                PreparedMealPendingFillOption(
                  key: stockKey,
                  icon: const Icon(Icons.inventory_2_outlined),
                  title: l10n.preparedMealFillStock,
                  description: l10n.preparedMealFillStockDescription,
                  onTap: () =>
                      Navigator.of(context)
                          .pop(const PreparedMealPendingFillPickStock()),
                ),
                PreparedMealPendingFillOption(
                  key: sourceKey(PreparedMealFoodSource.search),
                  icon: const Icon(Icons.search_rounded),
                  title: l10n.preparedMealFillSearch,
                  description: l10n.preparedMealFillSearchDescription,
                  onTap: () => Navigator.of(context).pop(
                    const PreparedMealPendingFillFind(
                      PreparedMealFoodSource.search,
                    ),
                  ),
                ),
                PreparedMealPendingFillOption(
                  key: sourceKey(PreparedMealFoodSource.barcode),
                  icon: const BarcodeIcon(),
                  title: l10n.preparedMealFillBarcode,
                  description: l10n.preparedMealFillBarcodeDescription,
                  onTap: () => Navigator.of(context).pop(
                    const PreparedMealPendingFillFind(
                      PreparedMealFoodSource.barcode,
                    ),
                  ),
                ),
                PreparedMealPendingFillOption(
                  key: sourceKey(PreparedMealFoodSource.ai),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  title: l10n.preparedMealFillAi,
                  description: l10n.preparedMealFillAiDescription,
                  onTap: () => Navigator.of(context).pop(
                    const PreparedMealPendingFillFind(
                      PreparedMealFoodSource.ai,
                    ),
                  ),
                ),
                PreparedMealPendingFillOption(
                  key: shoppingListKey,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  title: l10n.preparedMealFillShoppingList,
                  description: l10n.preparedMealFillShoppingListDescription,
                  onTap: () =>
                      Navigator.of(context)
                          .pop(const PreparedMealPendingFillShoppingList()),
                ),
              ],
            ),
            if (canIgnore)
              Center(
                child: TextButton(
                  key: ignoreKey,
                  onPressed: () =>
                      Navigator.of(context)
                          .pop(const PreparedMealPendingFillIgnore()),
                  child: Text(l10n.preparedMealFillIgnore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
