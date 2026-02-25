import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_barcode_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CalorieBarcodeScanPage extends ConsumerStatefulWidget {
  const CalorieBarcodeScanPage({
    super.key,
    this.barcodeStreamForTesting,
  });

  final Stream<String>? barcodeStreamForTesting;

  @override
  ConsumerState<CalorieBarcodeScanPage> createState() {
    return _CalorieBarcodeScanPageState();
  }
}

class _CalorieBarcodeScanPageState extends ConsumerState<CalorieBarcodeScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  StreamSubscription<String>? _testBarcodeSubscription;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    final stream = widget.barcodeStreamForTesting;
    if (stream == null) {
      return;
    }
    _testBarcodeSubscription = stream.listen((barcode) {
      _handleDetectedBarcode(barcode);
    });
  }

  @override
  void dispose() {
    _testBarcodeSubscription?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.caloriesBarcodeScannerTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            key: CalorieBarcodeScanKeys.scannerView,
            controller: _scannerController,
            onDetect: _onDetect,
          ),
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
    if (_isResolving) {
      return;
    }

    setState(() {
      _isResolving = true;
    });
    await _scannerController.stop();

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
        await _scannerController.start();
      }
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
        await context.push(AppRoutes.homeCaloriesEntryCreate);
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
          _showSnackBar(
            AppLocalizations.of(context)!.caloriesOcrFailed,
          );
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

  Future<void> _openEditor({
    required CalorieProductProfile profile,
    required CalorieScannedSourceRef scannedSourceRef,
  }) {
    return context.push(
      AppRoutes.homeCaloriesEntryCreate,
      extra: CalorieEntryCreateArgs(
        prefilledProfile: profile,
        scannedSourceRef: scannedSourceRef,
      ),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _CalorieNotFoundAction { manual, ocr, cancel }
