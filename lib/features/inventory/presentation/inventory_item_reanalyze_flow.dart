import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/food_estimate_level_change.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_search_request.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Estimates an AI food again ("Neu analysieren", #763): the AI page starts
/// from the food's photos and description, and the new estimate replaces
/// its name, nutrition and ingredients. The stock stays, also once some of
/// it is eaten, and so do the diary entries already eaten.
///
/// The undo snackbar goes to `messenger`, which outlives [run]'s context.
abstract final class InventoryItemReanalyzeFlow {
  /// Runs the AI page for [item]. Returns whether the item changed; false
  /// when the user went back or saving failed.
  static Future<bool> run({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required ScaffoldMessengerState messenger,
  }) async {
    final result = await context.push<InventoryReceiptManualProductResult>(
      AppRoutes.homeProductSearchHub,
      extra: InventoryManualProductSearchRequest(
        item: item,
        startsWithAi: true,
      ),
    );
    final estimated = result?.item;
    // Only a new estimate replaces the food; the hub's search picks none.
    if (estimated == null ||
        estimated.productSnapshot.aiEstimate == null ||
        !context.mounted) {
      return false;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final saved = await _guard(
      () => controller.changeAiFood(
        item.id,
        (stored) => stored.withNewEstimate(estimated),
      ),
    );
    if (!saved) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          l10n.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
      }
      return false;
    }
    messenger.showAppSnackBar(
      l10n.inventoryItemUpdatedMessage,
      onUndo: () => _guard(
        () => controller.changeAiFood(
          item.id,
          (stored) => stored.withAiFoodOf(
            item,
            foodFingerprint: item.resolvedFoodFingerprint,
          ),
        ),
      ),
    );
    return true;
  }

  static Future<bool> _guard(Future<bool> Function() save) async {
    try {
      return await save();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Estimating an AI food again failed.',
        name: 'InventoryItemReanalyzeFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
