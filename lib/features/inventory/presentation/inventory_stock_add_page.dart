import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_add_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Item details of a new product before it goes into the Vorrat: the label
/// of one package, how many packages to add, and the item's actions.
///
/// Pops with an [InventoryStockAddResult]. There is no replace or remove,
/// since the product is not in the Vorrat yet.
class InventoryStockAddPage extends ConsumerStatefulWidget {
  /// Creates the page for [item].
  const new({required this.item, this.initialPackages = 1, super.key});

  /// Key of the confirm button.
  static const confirmKey = Key('inventory_stock_add_confirm');

  /// Key of the button that takes one package away.
  static const decreaseKey = Key('inventory_stock_add_decrease');

  /// Key of the button that adds one package.
  static const increaseKey = Key('inventory_stock_add_increase');

  /// Key of the package count.
  static const countKey = Key('inventory_stock_add_count');

  /// The new product.
  final InventoryItem item;

  /// Number of packages to start with, at least one.
  final int initialPackages;

  @override
  ConsumerState<InventoryStockAddPage> createState() =>
      _InventoryStockAddPageState();
}

class _InventoryStockAddPageState extends ConsumerState<InventoryStockAddPage> {
  // The card sits below the page's own snackbar messenger, so its context
  // shows the shopping list hint on this page.
  final GlobalKey _cardKey = GlobalKey();
  late int _packages = widget.initialPackages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    // The label shows one package, also after the editor changed its size.
    final package = item.withDerivedAmount(
      quantity: 1,
      fallbackUnit: item.amountUnit,
    );
    final isOnShoppingList = ref.watch(
      sourceItemInActiveShoppingListProvider((
        name: item.name,
        brand: item.brand,
        initialQuantity: item.initialQuantity,
        unitPrice: item.unitPrice,
      )),
    );
    final weight = item.weight?.trim() ?? '';

    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: null,
      confirmButtonKey: InventoryStockAddPage.confirmKey,
      confirmLabel: l10n.inventoryStockAddConfirm(_packages),
      onConfirm: () =>
          Navigator.of(context).pop(InventoryStockAddConfirmed(_packages)),
      cancelButtonKey: const Key('inventory_stock_add_close'),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          caption: weight.isEmpty
              ? null
              : l10n.receiptReviewPackageSize(weight),
          imageUrl: item.imageUrl,
        ),
        if (_packageNutrition(package) case final nutrition?)
          EatLabelTable(
            rows: nutritionFactsRows(
              context,
              eaten: nutrition.eaten,
              per100: nutrition.per100,
              unknownEaten: l10n.eatPageAmountUnknown,
            ),
            per100Header: l10n.caloriesEntryPer100Label(_unit(l10n, item)),
            eatenHeader: switch (nutrition.amount) {
              final amount? => l10n.inventoryEatSheetAmountWithUnit(
                formatInventoryNutritionValue(amount),
                _unit(l10n, item),
              ),
              null => l10n.eatPageAmountUnknown,
            },
          ),
        EatCountRow(
          label: l10n.eatPagePackages,
          count: _packages,
          decreaseTooltip: l10n.eatPageRemovePackage,
          increaseTooltip: l10n.eatPageAddPackage,
          onDecrease: _packages > 1
              ? () => setState(() => _packages -= 1)
              : null,
          onIncrease: () => setState(() => _packages += 1),
          decreaseKey: InventoryStockAddPage.decreaseKey,
          increaseKey: InventoryStockAddPage.increaseKey,
          valueKey: InventoryStockAddPage.countKey,
        ),
        EatItemActionsCard(
          key: _cardKey,
          isOnShoppingList: isOnShoppingList,
          actions: const [
            InventoryItemHubAction.addToShoppingList,
            InventoryItemHubAction.edit,
          ],
          onPicked: _run,
        ),
      ],
    );
  }

  /// Nutrition of one package, or per 100 only when the package has no
  /// weight, such as a pack of rolls.
  static EatNutrition? _packageNutrition(InventoryItem package) {
    final nutrition = package.nutrition;
    if (nutrition == null || !nutrition.hasAnyNutritionValue) {
      return null;
    }
    final amount = consumableInventoryAmount(package);
    final isWeighed =
        package.amountUnit == InventoryAmountUnit.gram ||
        package.amountUnit == InventoryAmountUnit.milliliter;
    if (amount == null || !isWeighed) {
      return EatNutrition.per100Only(nutrition);
    }
    return EatNutrition.fromPer100(nutrition, amount / package.amountScale);
  }

  static String _unit(AppLocalizations l10n, InventoryItem item) {
    return item.amountUnit == InventoryAmountUnit.milliliter
        ? l10n.inventoryUnitMilliliter
        : l10n.caloriesUnitGram;
  }

  Future<void> _run(InventoryItemHubAction action) async {
    if (action == InventoryItemHubAction.edit) {
      Navigator.of(context).pop(InventoryStockAddEdit(_packages));
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final revert = await controller.buyAgainItem(widget.item);
    final cardContext = _cardKey.currentContext;
    if (!mounted || cardContext == null || !cardContext.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(cardContext);
    if (revert == null) {
      messenger.showAppSnackBar(
        l10n.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemBuyAgainSucceeded,
      onUndo: () => controller.undoBuyAgainItem(revert),
    );
  }
}
