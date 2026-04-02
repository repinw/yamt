import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_barcode_flow_controller.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CalorieBarcodeScanPage extends ConsumerStatefulWidget {
  const CalorieBarcodeScanPage({super.key, this.inventoryContext});

  final CalorieInventoryCreateContext? inventoryContext;

  @override
  ConsumerState<CalorieBarcodeScanPage> createState() {
    return _CalorieBarcodeScanPageState();
  }
}

class _CalorieBarcodeScanPageState
    extends ConsumerState<CalorieBarcodeScanPage> {
  static const _logName = 'CalorieBarcodeScanPage';

  final MobileScannerController _scannerController = MobileScannerController();
  bool _isResolving = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope<void>(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.caloriesBarcodeScannerTitle)),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
            if (_isResolving)
              ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: AppInsets.card,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox.square(
                            dimension: AppSizes.inlineProgressIndicator,
                            child: CircularProgressIndicator(
                              strokeWidth: AppSizes.progressStrokeWidth,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(l10n.caloriesBarcodeResolving),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final rawBarcode = capture.barcodes.firstOrNull?.rawValue;
    if (rawBarcode == null || rawBarcode.trim().isEmpty) {
      return;
    }
    await _handleDetectedBarcode(rawBarcode);
  }

  Future<void> _handleDetectedBarcode(String rawBarcode) async {
    if (!mounted || _isResolving) {
      return;
    }

    setState(() {
      _isResolving = true;
    });
    await _stopScanner();

    try {
      final outcome = await ref
          .read(calorieBarcodeFlowControllerProvider.notifier)
          .resolveBarcode(rawBarcode);
      if (!mounted) {
        return;
      }
      await _handleOutcome(
        outcome: outcome,
        scannedBarcode: normalizeBarcode(rawBarcode),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
        await _startScanner();
      }
    }
  }

  Future<void> _stopScanner() async {
    if (!mounted) {
      return;
    }
    try {
      await _scannerController.stop();
    } catch (error, stackTrace) {
      log(
        'Stopping barcode scanner failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startScanner() async {
    if (!mounted) {
      return;
    }
    try {
      await _scannerController.start();
    } catch (error, stackTrace) {
      log(
        'Starting barcode scanner failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleOutcome({
    required CalorieLookupOutcome outcome,
    required String scannedBarcode,
  }) async {
    switch (outcome.status) {
      case CalorieLookupStatus.foundSingle:
        final product = outcome.product;
        if (product == null) {
          return;
        }
        await _syncInventoryBarcodeIfNeeded(
          profile: product,
          scannedBarcode: scannedBarcode,
        );
        await _openEditor(
          profile: product,
          scannedSourceRef: CalorieScannedSourceRef(
            barcode: scannedBarcode,
            source: product.source,
            offProductId: product.offProductId,
          ),
        );
        return;
      case CalorieLookupStatus.foundMultiple:
        final selected = await _pickCandidate(outcome.candidates);
        if (selected == null) {
          return;
        }
        await ref
            .read(calorieBarcodeFlowControllerProvider.notifier)
            .persistSelectedCandidate(selected.profile);
        if (!mounted) {
          return;
        }
        await _syncInventoryBarcodeIfNeeded(
          profile: selected.profile,
          scannedBarcode: scannedBarcode,
        );
        await _openEditor(
          profile: selected.profile,
          scannedSourceRef: CalorieScannedSourceRef(
            barcode: scannedBarcode,
            source: selected.profile.source,
            offProductId: selected.profile.offProductId,
          ),
        );
        return;
      case CalorieLookupStatus.notFound:
        await _handleNotFound(scannedBarcode);
        return;
      case CalorieLookupStatus.failed:
        _showSnackBar(
          AppLocalizations.of(context)!.caloriesBarcodeLookupFailed,
        );
        return;
    }
  }

  Future<CalorieProductCandidate?> _pickCandidate(
    List<CalorieProductCandidate> candidates,
  ) {
    return showModalBottomSheet<CalorieProductCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CalorieBarcodeCandidatePickerSheet(
          candidates: candidates,
          onSelect: (candidate) => context.pop(candidate),
        );
      },
    );
  }

  Future<void> _handleNotFound(String scannedBarcode) async {
    final action = await _showNotFoundDialog();
    if (!mounted) {
      return;
    }

    switch (action) {
      case _CalorieNotFoundAction.manual:
        await _openManualEditor();
        return;
      case _CalorieNotFoundAction.ocr:
        final ocrResult = await ref
            .read(calorieBarcodeFlowControllerProvider.notifier)
            .scanNutritionLabel(barcode: scannedBarcode);
        if (!mounted) {
          return;
        }
        if (ocrResult.status == CalorieNutritionOcrStatus.succeeded &&
            ocrResult.profile != null) {
          await _openEditor(
            profile: ocrResult.profile!,
            scannedSourceRef: CalorieScannedSourceRef(
              barcode: scannedBarcode,
              source: CalorieProductSource.ocr,
              offProductId: null,
            ),
          );
          return;
        }
        if (ocrResult.status == CalorieNutritionOcrStatus.failed) {
          _showSnackBar(AppLocalizations.of(context)!.caloriesOcrFailed);
        }
        return;
      case _CalorieNotFoundAction.cancel:
      case null:
        return;
    }
  }

  Future<_CalorieNotFoundAction?> _showNotFoundDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<_CalorieNotFoundAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: CalorieBarcodeScanKeys.notFoundDialog,
          title: Text(l10n.caloriesBarcodeNotFoundTitle),
          content: Text(l10n.caloriesBarcodeNotFoundMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(_CalorieNotFoundAction.cancel),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            TextButton(
              key: CalorieBarcodeScanKeys.notFoundManualButton,
              onPressed: () => context.pop(_CalorieNotFoundAction.manual),
              child: Text(l10n.caloriesBarcodeNotFoundManualAction),
            ),
            FilledButton(
              key: CalorieBarcodeScanKeys.notFoundOcrButton,
              onPressed: () => context.pop(_CalorieNotFoundAction.ocr),
              child: Text(l10n.caloriesBarcodeNotFoundOcrAction),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openManualEditor() async {
    await context.push(
      AppRoutes.homeCaloriesEntryCreate,
      extra: CalorieEntryCreateArgs(
        prefilledProfile: null,
        inventoryContext: widget.inventoryContext,
      ),
    );
    await _closeIfPendingResolved();
  }

  Future<void> _openEditor({
    required CalorieProductProfile profile,
    required CalorieScannedSourceRef scannedSourceRef,
  }) async {
    await context.push(
      AppRoutes.homeCaloriesEntryCreate,
      extra: CalorieEntryCreateArgs(
        prefilledProfile: profile,
        scannedSourceRef: scannedSourceRef,
        inventoryContext: widget.inventoryContext,
      ),
    );
    await _closeIfPendingResolved();
  }

  Future<void> _closeIfPendingResolved() async {
    final pendingConsumptionId = widget.inventoryContext?.pendingConsumptionId;
    if (pendingConsumptionId == null || !mounted) {
      return;
    }

    final hasPendingConsumption = ref
        .read(inventoryItemsControllerProvider.notifier)
        .hasPendingConsumption(pendingConsumptionId);
    if (!hasPendingConsumption && context.canPop()) {
      context.pop();
    }
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) {
      return;
    }

    final pendingConsumptionId = widget.inventoryContext?.pendingConsumptionId;
    if (pendingConsumptionId == null) {
      return;
    }

    unawaited(
      ref
          .read(inventoryItemsControllerProvider.notifier)
          .discardPendingConsumption(pendingConsumptionId),
    );
  }

  Future<void> _syncInventoryBarcodeIfNeeded({
    required CalorieProductProfile profile,
    required String scannedBarcode,
  }) async {
    final inventoryContext = widget.inventoryContext;
    if (inventoryContext == null) {
      return;
    }

    final resolvedBarcode = scannedBarcode.trim().isEmpty
        ? profile.barcode
        : scannedBarcode;
    if (resolvedBarcode.trim().isEmpty) {
      return;
    }

    await ref
        .read(inventoryItemsControllerProvider.notifier)
        .setItemBarcode(
          itemId: inventoryContext.inventoryItemId,
          barcode: resolvedBarcode,
        );
    await ref
        .read(calorieBarcodeBackfillRepositoryProvider)
        .submitUserProvidedBarcode(
          fingerprint: inventoryContext.foodFingerprint,
          barcode: resolvedBarcode,
          itemName: inventoryContext.itemName,
          brand: inventoryContext.itemBrand,
        );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _CalorieNotFoundAction { manual, ocr, cancel }
