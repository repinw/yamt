import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/domain/inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_quick_eat_picker.g.dart';

/// Application-facing contract for the inventory quick-eat picker UI.
abstract interface class InventoryQuickEatPicker {
  /// Opens the item picker and returns the selected request, if any.
  Future<InventoryItemEatRequest?> pickItem({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  });

  /// Opens the item picker and also returns the selected continuation intent.
  Future<InventoryItemEatSheetResult?> pickItemResult({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    required InventoryItemEatSheetIntent confirmIntent,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    String? addMoreActionText,
  });

  /// Opens the prepared-meal picker and returns the selected request, if any.
  Future<InventoryPreparedMealEatRequest?> pickPreparedMeal({
    required BuildContext context,
    required PreparedMeal meal,
    required bool useRootNavigator,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  });
}

/// Composition root supplies the presentation implementation.
@riverpod
InventoryQuickEatPicker inventoryQuickEatPicker(Ref ref) =>
    const _UnconfiguredInventoryQuickEatPicker();

class _UnconfiguredInventoryQuickEatPicker implements InventoryQuickEatPicker {
  const _UnconfiguredInventoryQuickEatPicker();

  Never _fail() => throw UnsupportedError(
    'InventoryQuickEatPicker must be overridden by the application shell.',
  );

  @override
  Future<InventoryItemEatRequest?> pickItem({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) => _fail();

  @override
  Future<InventoryItemEatSheetResult?> pickItemResult({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    required InventoryItemEatSheetIntent confirmIntent,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    String? addMoreActionText,
  }) => _fail();

  @override
  Future<InventoryPreparedMealEatRequest?> pickPreparedMeal({
    required BuildContext context,
    required PreparedMeal meal,
    required bool useRootNavigator,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) => _fail();
}
