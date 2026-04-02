import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/models/calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryCalorieBridgeFlow {
  const InventoryCalorieBridgeFlow._();

  static Future<void> onEatCompleted({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem itemBeforeMutation,
    required int consumedAmount,
    required String pendingConsumptionId,
  }) async {
    final inventoryContext = await _buildInventoryContext(
      context: context,
      item: itemBeforeMutation,
      pendingConsumptionId: pendingConsumptionId,
      consumedAmount: consumedAmount,
    );
    if (!context.mounted || inventoryContext == null) {
      await _discardPendingConsumption(
        ref: ref,
        pendingConsumptionId: pendingConsumptionId,
      );
      return;
    }

    final localProfile = _buildProfileFromInventoryItem(itemBeforeMutation);
    if (localProfile == null) {
      await _discardPendingConsumption(
        ref: ref,
        pendingConsumptionId: pendingConsumptionId,
      );
      if (context.mounted) {
        _showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.inventoryItemActionFailed,
        );
      }
      return;
    }

    final barcode = itemBeforeMutation.normalizedBarcode;
    await _openEditor(
      context: context,
      profile: localProfile,
      inventoryContext: inventoryContext,
      scannedSourceRef: barcode == null
          ? null
          : CalorieScannedSourceRef(
              barcode: barcode,
              source: localProfile.source,
              offProductId: localProfile.offProductId,
            ),
    );
  }

  static CalorieProductProfile? _buildProfileFromInventoryItem(
    InventoryItem item,
  ) {
    final nutrition = item.nutrition;
    if (nutrition?.hasAnyNutritionValue != true) {
      return null;
    }

    final barcode = item.normalizedBarcode ?? 'inventory-${item.id}';

    return CalorieProductProfile(
      barcode: barcode,
      name: item.name,
      brand: item.brand,
      per100Kcal: nutrition?.per100Kcal ?? 0,
      per100Protein: nutrition?.per100Protein ?? 0,
      per100Carbs: nutrition?.per100Carbs ?? 0,
      per100Fat: nutrition?.per100Fat ?? 0,
      source: CalorieProductSource.userOverride,
      offProductId: _resolveOffProductId(item.globalFoodItemId),
      imageUrl: item.imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static String? _resolveOffProductId(String? globalFoodItemId) {
    final normalizedId = globalFoodItemId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      return null;
    }
    if (normalizedId.startsWith('off-')) {
      return normalizedId;
    }
    return null;
  }

  static Future<CalorieInventoryCreateContext?> _buildInventoryContext({
    required BuildContext context,
    required InventoryItem item,
    required String pendingConsumptionId,
    required int consumedAmount,
  }) async {
    final unit = item.amountUnit;
    if (item.usesAmountProgress &&
        unit != null &&
        (unit == InventoryAmountUnit.gram ||
            unit == InventoryAmountUnit.milliliter)) {
      return CalorieInventoryCreateContext(
        inventoryItemId: item.id,
        foodFingerprint: item.resolvedFoodFingerprint,
        pendingConsumptionId: pendingConsumptionId,
        inventoryAmountToRestore: consumedAmount,
        itemName: item.name,
        itemBrand: item.brand,
        consumedAmount: consumedAmount.toDouble(),
        consumedUnit: unit == InventoryAmountUnit.gram
            ? ConsumedUnit.grams
            : ConsumedUnit.milliliters,
      );
    }

    final portion = await _requestManualPortion(context: context);
    if (portion == null) {
      return null;
    }
    return CalorieInventoryCreateContext(
      inventoryItemId: item.id,
      foodFingerprint: item.resolvedFoodFingerprint,
      pendingConsumptionId: pendingConsumptionId,
      inventoryAmountToRestore: consumedAmount,
      itemName: item.name,
      itemBrand: item.brand,
      consumedAmount: portion.amount,
      consumedUnit: portion.unit,
    );
  }

  static Future<_ManualPortionResult?> _requestManualPortion({
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var selectedUnit = ConsumedUnit.grams;
    String? errorText;

    return showDialog<_ManualPortionResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(l10n.inventoryBarcodePortionDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.caloriesEntryAmountLabel,
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ConsumedUnit>(
                    initialValue: selectedUnit,
                    decoration: InputDecoration(
                      labelText: l10n.caloriesEntryUnitLabel,
                    ),
                    items: ConsumedUnit.values
                        .map((unit) {
                          return DropdownMenuItem<ConsumedUnit>(
                            value: unit,
                            child: Text(unit.localizedName(l10n)),
                          );
                        })
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedUnit = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => dialogContext.pop(),
                  child: Text(l10n.inventoryReceiptReviewCancelAction),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = _parsePositiveAmount(controller.text);
                    if (amount == null) {
                      setState(() {
                        errorText = l10n.caloriesPositiveNumberValidation;
                      });
                      return;
                    }
                    dialogContext.pop(
                      _ManualPortionResult(amount: amount, unit: selectedUnit),
                    );
                  },
                  child: Text(l10n.inventoryBarcodePortionDialogConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static double? _parsePositiveAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static Future<void> _openEditor({
    required BuildContext context,
    required CalorieProductProfile profile,
    required CalorieInventoryCreateContext inventoryContext,
    required CalorieScannedSourceRef? scannedSourceRef,
  }) {
    return context.push(
      AppRoutes.homeCaloriesEntryCreate,
      extra: CalorieEntryCreateArgs(
        prefilledProfile: profile,
        scannedSourceRef: scannedSourceRef,
        inventoryContext: inventoryContext,
      ),
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _discardPendingConsumption({
    required WidgetRef ref,
    required String pendingConsumptionId,
  }) {
    return ref
        .read(inventoryItemsControllerProvider.notifier)
        .discardPendingConsumption(pendingConsumptionId);
  }
}

class _ManualPortionResult {
  const _ManualPortionResult({required this.amount, required this.unit});

  final double amount;
  final ConsumedUnit unit;
}
