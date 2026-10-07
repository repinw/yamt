import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_product_eat_flow_contract.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Diary completion handler for product search hub.
class DiaryProductSearchHubCompletionHandler
    implements ProductSearchHubCompletionHandler {
  /// Creates a diary completion handler.
  const new({required this._eatCoordinator});

  final InventoryManualProductEatCoordinator _eatCoordinator;

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await _eatCoordinator.complete(
      context: context,
      container: ProviderScope.containerOf(context, listen: false),
      l10n: l10n,
      result: result,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
    );
    if (!context.mounted) {
      return const ProductSearchHubCompletionResult.none();
    }
    if (outcome.status == InventoryManualProductEatStatus.planned) {
      final plan = outcome.plan!;
      final container = ProviderScope.containerOf(context, listen: false);
      ScaffoldMessenger.of(context).showAppSnackBar(
        l10n.diaryPlanSaved,
        onUndo: () =>
            InventoryItemEatFlow.undoPlan(container: container, plan: plan),
      );
      return const ProductSearchHubCompletionResult.closeHub();
    }
    if (outcome.status != InventoryManualProductEatStatus.saved ||
        outcome.item == null) {
      log(
        'Product search hub result $sourceKey ended with '
        '${outcome.status.name}.',
        name: 'DiaryProductSearchHubCompletionHandler',
      );
      if (outcome.status == InventoryManualProductEatStatus.failed) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          switch (outcome.planFailure) {
            null => l10n.inventoryManualAddSaveFailed,
            final failure => InventoryItemEatFlow.failureMessage(l10n, failure),
          },
          tone: AppSnackBarTone.error,
        );
      }
      if (outcome.status == InventoryManualProductEatStatus.canceled) {
        return const ProductSearchHubCompletionResult.canceled();
      }
      return const ProductSearchHubCompletionResult.none();
    }
    return const ProductSearchHubCompletionResult.closeHub(saved: true);
  }
}
