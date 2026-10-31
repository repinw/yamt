import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_pack_choice_sheet.dart';

const _logName = 'InventoryPackEatFlow';

/// Takes the stock of a food found in the diary from a Vorrat pack of the
/// same product (#326).
abstract final class InventoryPackEatFlow {
  /// Asks from which Vorrat pack of [item]'s product the stock comes, when
  /// the Vorrat holds one with its barcode. Without one, or when the Vorrat
  /// cannot be read, the food is eaten without stock. Returns null when the
  /// user dismisses the question.
  static Future<InventoryPackChoice?> ask(
    BuildContext context, {
    required ProviderContainer container,
    required InventoryItem item,
  }) async {
    final List<InventoryItem> packs;
    try {
      packs = await container
          .read(inventoryItemEatControllerProvider.notifier)
          .loadPacksWithBarcode(item.barcode);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read the Vorrat packs of ${item.name}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const InventoryPackSkipped();
    }
    if (packs.isEmpty || !context.mounted) {
      return const InventoryPackSkipped();
    }
    return await showInventoryPackChoiceSheet(context, packs: packs);
  }

  /// Eats or plans [request], picked for the found product [from], from
  /// the Vorrat [pack] of the same product, without asking again. A plan
  /// keeps the pack, so accepting it takes the stock there. The amount moves
  /// into the pack's unit; when it cannot, the pack's eat page asks for it.
  /// Returns the saved entry, or null.
  static Future<CalorieEntry?> eat(
    BuildContext context, {
    required InventoryItem from,
    required InventoryItem pack,
    required InventoryItemEatRequest request,
  }) {
    final amount = inventoryAmountInPack(
      from: from,
      amount: request.inventoryAmount,
      pack: pack,
    );
    if (amount == null) {
      return InventoryItemEatFlow.eat(
        context: context,
        item: pack,
        initialLoggedAt: request.loggedAt,
        initialMealType: request.mealType,
      );
    }
    return InventoryItemEatFlow.logRequest(
      context: context,
      item: pack,
      request: InventoryItemEatRequest(
        inventoryAmount: amount,
        loggedAt: request.loggedAt,
        mealType: request.mealType,
        calorieAmount: request.calorieAmount,
        calorieUnit: request.calorieUnit,
        portionBaseAmount: request.portionBaseAmount,
        portionBaseUnit: request.portionBaseUnit,
        portionCount: request.portionCount,
        portionLabel: request.portionLabel,
        isPlan: request.isPlan,
      ),
    );
  }
}
