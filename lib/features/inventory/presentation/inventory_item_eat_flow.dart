import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory item eat flow.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class InventoryItemEatFlow {
  const InventoryItemEatFlow._();

  static const _uuid = Uuid();

  /// Should await completion.
  static bool shouldAwaitCompletion(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) {
    return canDirectlySaveInventoryItemEatRequest(item, request);
  }

  /// Complete.
  static Future<bool> complete({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem itemBeforeMutation,
    required InventoryItemEatRequest request,
    required String pendingConsumptionId,
  }) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final successMessage = l10n.inventoryManualAddEatSucceeded;
      final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
        itemBeforeMutation,
      );
      if (profile == null) {
        await _discardPendingConsumption(
          ref: ref,
          pendingConsumptionId: pendingConsumptionId,
        );
        if (context.mounted) {
          _showSnackBar(
            context: context,
            message: l10n.inventoryItemActionFailed,
          );
        }
        return false;
      }

      final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
        item: itemBeforeMutation,
        pendingConsumptionId: pendingConsumptionId,
        request: request,
      );
      final scannedSourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
        item: itemBeforeMutation,
        profile: profile,
      );

      if (canDirectlySaveInventoryItemEatRequest(itemBeforeMutation, request)) {
        final saved = await saveDirectEntry(
          ref: ref,
          profile: profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: scannedSourceRef,
          loggedAt: request.loggedAt,
          mealType: request.mealType,
        );
        if (saved) {
          if (context.mounted) {
            _showSnackBar(context: context, message: successMessage);
          }
          return true;
        }

        await _discardPendingConsumption(
          ref: ref,
          pendingConsumptionId: pendingConsumptionId,
        );
        if (context.mounted) {
          _showSnackBar(context: context, message: l10n.caloriesSaveFailed);
        }
        return false;
      }

      if (!context.mounted) {
        await _discardPendingConsumption(
          ref: ref,
          pendingConsumptionId: pendingConsumptionId,
        );
        return false;
      }

      final saved = await context.push<bool>(
        AppRoutes.homeCaloriesEntryCreate,
        extra: CalorieEntryCreateArgs(
          prefilledProfile: profile,
          scannedSourceRef: scannedSourceRef,
          inventoryContext: inventoryContext,
          preselectedMealType: request.mealType,
          preselectedLoggedAt: request.loggedAt,
        ),
      );
      if (saved == true && context.mounted) {
        _showSnackBar(context: context, message: successMessage);
      }
      return saved == true;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Eat flow failed unexpectedly.',
        name: 'InventoryItemEatFlow',
        error: error,
        stackTrace: stackTrace,
      );
      await _discardPendingConsumption(
        ref: ref,
        pendingConsumptionId: pendingConsumptionId,
      );
      if (!context.mounted) {
        return false;
      }
      _showSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.inventoryItemActionFailed,
      );
      return false;
    }
  }

  static Future<void> _discardPendingConsumption({
    required WidgetRef ref,
    required String pendingConsumptionId,
  }) {
    return ref
        .read(inventoryItemsControllerProvider.notifier)
        .discardPendingConsumption(pendingConsumptionId);
  }

  /// Save a direct inventory-backed calorie entry.
  static Future<bool> saveDirectEntry({
    required WidgetRef ref,
    required CalorieProductProfile profile,
    required CalorieInventoryCreateContext inventoryContext,
    required CalorieScannedSourceRef? scannedSourceRef,
    required DateTime loggedAt,
    required MealType mealType,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      return false;
    }

    final now = DateTime.now();
    final entry = CalorieEntry.create(
      id: _uuid.v4(),
      userId: user.uid,
      name: profile.name,
      brand: profile.brand,
      imageUrl: profile.imageUrl,
      mealType: mealType,
      consumedAmount: inventoryContext.consumedAmount,
      consumedUnit: inventoryContext.consumedUnit,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
      sourceInventoryItemId: inventoryContext.inventoryItemId,
      sourceInventoryAmountToRestore: inventoryContext.inventoryAmountToRestore,
      loggedAt: loggedAt,
      createdAt: now,
      updatedAt: now,
    );

    return ref
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(
          entry,
          inventoryContext: inventoryContext,
          scannedSourceRef: scannedSourceRef,
          persistEntry: (entry) {
            return ref
                .read(inventoryBackedCalorieEntrySaveFlowProvider)
                .saveEntry(
                  entry: entry,
                  pendingConsumptionId: inventoryContext.pendingConsumptionId,
                );
          },
        );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
