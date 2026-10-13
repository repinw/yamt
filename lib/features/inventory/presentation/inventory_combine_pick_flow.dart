import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Picks the foods that join the meal of an item hub, from the hub's item
/// card or from the meal's own add link.
abstract final class InventoryCombinePickFlow {
  /// Opens the inventory to pick foods for the meal of [hubItem]. Stock
  /// items join with a default amount. A food found by search joins with
  /// the amount entered on its eat page. [context] shows the hint for a food
  /// that cannot join.
  static Future<void> pick({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem hubItem,
    required bool includesHubItem,
  }) async {
    // A second tap while the pick page opens would stack another one.
    if (_isPicking) {
      return;
    }
    _isPicking = true;
    try {
      await _pick(
        context: context,
        ref: ref,
        hubItem: hubItem,
        includesHubItem: includesHubItem,
      );
    } finally {
      _isPicking = false;
    }
  }

  static bool _isPicking = false;

  static Future<void> _pick({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem hubItem,
    required bool includesHubItem,
  }) async {
    final notifier = ref.read(
      inventoryItemCombineControllerProvider(hubItem.id).notifier,
    );
    final items = ref.read(inventoryItemsControllerProvider).value;
    final picked = await showInventoryCombinePickPage(
      context,
      candidates: notifier.candidatesFrom(
        items ?? const <InventoryItem>[],
        includesHub: includesHubItem,
      ),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    for (final item in picked.stock) {
      if (!InventoryCombinedEatService.canCombine(item) ||
          !notifier.addWithDefaultAmount(item)) {
        _showCannotCombine(context);
      }
    }
    if (picked.searched case (:final result, :final request)) {
      final item = result.item;
      if (!InventoryCombinedEatService.canCombine(item) ||
          !canDirectlySaveInventoryItemEatRequest(item, request)) {
        _showCannotCombine(context);
        return;
      }
      notifier.add(item, request, searchResult: result);
    }
  }

  static void _showCannotCombine(BuildContext context) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.eatPageCombineNeedsNutrition,
      tone: AppSnackBarTone.error,
    );
  }
}
