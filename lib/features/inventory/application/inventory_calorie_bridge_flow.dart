import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/models/calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/calories/provider/calorie_barcode_flow_controller.dart';
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
    final flags = ref.read(barcodeBackfillFeatureFlagsProvider);
    if (!flags.enableEatBridge) {
      return;
    }

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
    if (localProfile != null) {
      await _openEditor(
        context: context,
        profile: localProfile,
        inventoryContext: inventoryContext,
        scannedSourceRef: CalorieScannedSourceRef(
          barcode: localProfile.barcode,
          source: localProfile.source,
          offProductId: localProfile.offProductId,
        ),
      );
      return;
    }

    final barcode = itemBeforeMutation.normalizedBarcode;
    if (barcode != null) {
      final openedEditor = await _openEditorFromBarcode(
        context: context,
        ref: ref,
        barcode: barcode,
        inventoryContext: inventoryContext,
      );
      if (!openedEditor) {
        await _discardPendingConsumption(
          ref: ref,
          pendingConsumptionId: pendingConsumptionId,
        );
      }
      return;
    }

    final action = await _showMissingBarcodeActionSheet(context: context);
    if (!context.mounted || action == null) {
      await _discardPendingConsumption(
        ref: ref,
        pendingConsumptionId: pendingConsumptionId,
      );
      return;
    }

    switch (action) {
      case _InventoryMissingBarcodeAction.scanNow:
        if (!_isMobileBarcodeScanSupported()) {
          _showSnackBar(
            context: context,
            message: AppLocalizations.of(
              context,
            )!.inventoryBarcodeScanUnsupported,
          );
          await _discardPendingConsumption(
            ref: ref,
            pendingConsumptionId: pendingConsumptionId,
          );
          return;
        }
        await context.push(
          AppRoutes.homeCaloriesBarcodeScan,
          extra: CalorieBarcodeScanArgs(inventoryContext: inventoryContext),
        );
        return;
      case _InventoryMissingBarcodeAction.later:
        _showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.inventoryBarcodeLookupQueued,
        );
        await _discardPendingConsumption(
          ref: ref,
          pendingConsumptionId: pendingConsumptionId,
        );
        return;
    }
  }

  static CalorieProductProfile? _buildProfileFromInventoryItem(
    InventoryItem item,
  ) {
    final barcode = item.normalizedBarcode;
    final nutrition = item.nutrition;
    if (barcode == null || nutrition?.hasAnyNutritionValue != true) {
      return null;
    }

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

  static Future<bool> _openEditorFromBarcode({
    required BuildContext context,
    required WidgetRef ref,
    required String barcode,
    required CalorieInventoryCreateContext inventoryContext,
  }) async {
    final outcome = await ref
        .read(calorieBarcodeFlowControllerProvider.notifier)
        .resolveBarcode(barcode);
    if (!context.mounted) {
      return false;
    }

    switch (outcome.status) {
      case CalorieLookupStatus.foundSingle:
        final profile = outcome.product;
        if (profile == null) {
          return false;
        }
        await _openEditor(
          context: context,
          profile: profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: CalorieScannedSourceRef(
            barcode: barcode,
            source: profile.source,
            offProductId: profile.offProductId,
          ),
        );
        return true;
      case CalorieLookupStatus.foundMultiple:
        final selected = await _pickCandidate(
          context: context,
          candidates: outcome.candidates,
        );
        if (selected == null || !context.mounted) {
          return false;
        }
        await ref
            .read(calorieBarcodeFlowControllerProvider.notifier)
            .persistSelectedCandidate(selected.profile);
        if (!context.mounted) {
          return false;
        }
        await _openEditor(
          context: context,
          profile: selected.profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: CalorieScannedSourceRef(
            barcode: barcode,
            source: selected.profile.source,
            offProductId: selected.profile.offProductId,
          ),
        );
        return true;
      case CalorieLookupStatus.notFound:
      case CalorieLookupStatus.failed:
        _showSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.caloriesBarcodeLookupFailed,
        );
        return false;
    }
  }

  static Future<CalorieProductCandidate?> _pickCandidate({
    required BuildContext context,
    required List<CalorieProductCandidate> candidates,
  }) {
    return showModalBottomSheet<CalorieProductCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return CalorieBarcodeCandidatePickerSheet(
          candidates: candidates,
          onSelect: (candidate) => sheetContext.pop(candidate),
        );
      },
    );
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

  static Future<_InventoryMissingBarcodeAction?>
  _showMissingBarcodeActionSheet({required BuildContext context}) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<_InventoryMissingBarcodeAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(l10n.inventoryBarcodeMissingPromptTitle),
                subtitle: Text(l10n.inventoryBarcodeMissingPromptMessage),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined),
                title: Text(l10n.inventoryBarcodeMissingPromptScanNow),
                onTap: () {
                  sheetContext.pop(_InventoryMissingBarcodeAction.scanNow);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l10n.inventoryBarcodeMissingPromptLater),
                onTap: () {
                  sheetContext.pop(_InventoryMissingBarcodeAction.later);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _openEditor({
    required BuildContext context,
    required CalorieProductProfile profile,
    required CalorieInventoryCreateContext inventoryContext,
    required CalorieScannedSourceRef scannedSourceRef,
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

  static bool _isMobileBarcodeScanSupported() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
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

enum _InventoryMissingBarcodeAction { scanNow, later }
