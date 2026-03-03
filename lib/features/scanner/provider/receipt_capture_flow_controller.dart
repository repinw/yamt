import 'dart:async';
import 'dart:developer' show log;

import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/features/calories/data/calorie_barcode_backfill_repository.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

part 'receipt_capture_flow_controller.g.dart';

@riverpod
class ReceiptCaptureFlowController extends _$ReceiptCaptureFlowController {
  Future<ReceiptCaptureFlowResult>? _activeRun;

  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  Future<ReceiptCaptureFlowResult> run({
    required ReceiptInputSource source,
  }) async {
    final inFlight = _activeRun;
    if (inFlight != null) {
      return inFlight;
    }

    final operation = _runInternal(source: source);
    _activeRun = operation;
    try {
      return await operation;
    } finally {
      if (identical(_activeRun, operation)) {
        _activeRun = null;
      }
    }
  }

  Future<ReceiptCaptureFlowResult> _runInternal({
    required ReceiptInputSource source,
  }) async {
    if (!_isSourceSupported(source)) {
      const unsupported = ReceiptCaptureFlowResult.inputUnsupported(
        source: ReceiptInputSource.camera,
        errorCode: ReceiptInputErrorCodes.cameraNotSupported,
      );
      if (ref.mounted) {
        state = const AsyncData(unsupported);
      }
      return unsupported;
    }

    state = const AsyncLoading();

    final inputResult = await _pickInput(source);
    if (!ref.mounted) {
      return ReceiptCaptureFlowResult.inputFailed(
        source: source,
        errorCode: _inputUnexpectedCode(source),
      );
    }

    switch (inputResult.status) {
      case ReceiptInputStatus.selected:
        final selection = inputResult.selection;
        if (selection == null) {
          return _setAndReturn(
            ReceiptCaptureFlowResult.inputFailed(
              source: source,
              errorCode: _inputUnexpectedCode(source),
            ),
          );
        }
        return _analyzeSelection(source: source, selection: selection);
      case ReceiptInputStatus.canceled:
        return _setAndReturn(
          ReceiptCaptureFlowResult.inputCanceled(source: source),
        );
      case ReceiptInputStatus.unsupported:
        return _setAndReturn(
          ReceiptCaptureFlowResult.inputUnsupported(
            source: source,
            errorCode:
                inputResult.errorCode ??
                ReceiptInputErrorCodes.cameraNotSupported,
          ),
        );
      case ReceiptInputStatus.failed:
        return _setAndReturn(
          ReceiptCaptureFlowResult.inputFailed(
            source: source,
            errorCode: inputResult.errorCode ?? _inputUnexpectedCode(source),
          ),
        );
    }
  }

  bool _isSourceSupported(ReceiptInputSource source) {
    if (source != ReceiptInputSource.camera) {
      return true;
    }
    return ref.read(receiptCameraSupportedProvider);
  }

  Future<ReceiptInputResult> _pickInput(ReceiptInputSource source) {
    final inputRepository = ref.read(receiptInputRepositoryProvider);
    return switch (source) {
      ReceiptInputSource.camera => inputRepository.pickFromCamera(),
      ReceiptInputSource.file => inputRepository.pickFromFile(),
    };
  }

  Future<ReceiptCaptureFlowResult> _analyzeSelection({
    required ReceiptInputSource source,
    required ReceiptInputSelection selection,
  }) async {
    try {
      final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
      final analysisResult = await analysisRepository.analyzeSelection(
        selection,
      );
      if (!ref.mounted) {
        return ReceiptCaptureFlowResult.analysisFailed(
          source: source,
          errorCode: ReceiptAnalysisErrorCodes.unexpected,
        );
      }

      return switch (analysisResult) {
        ReceiptAnalysisSuccess(:final extraction) => _setAndReturn(
          ReceiptCaptureFlowResult.completed(
            source: source,
            extraction: extraction,
            mappedItems: _mapExtraction(extraction),
          ),
        ),
        ReceiptAnalysisFailure(:final errorCode) => _setAndReturn(
          ReceiptCaptureFlowResult.analysisFailed(
            source: source,
            errorCode: errorCode,
          ),
        ),
      };
    } catch (error, stackTrace) {
      log(
        'Receipt flow analysis failed unexpectedly',
        name: 'ReceiptCaptureFlowController',
        error: error,
        stackTrace: stackTrace,
      );
      return _setAndReturn(
        ReceiptCaptureFlowResult.analysisFailed(
          source: source,
          errorCode: ReceiptAnalysisErrorCodes.unexpected,
        ),
      );
    }
  }

  String _inputUnexpectedCode(ReceiptInputSource source) {
    return switch (source) {
      ReceiptInputSource.camera => ReceiptInputErrorCodes.cameraPickUnexpected,
      ReceiptInputSource.file => ReceiptInputErrorCodes.filePickUnexpected,
    };
  }

  ReceiptCaptureFlowResult _setAndReturn(ReceiptCaptureFlowResult result) {
    if (ref.mounted) {
      state = AsyncData(result);
    }
    return result;
  }

  List<FridgeItem> _mapExtraction(ReceiptAnalysisExtraction extraction) {
    final mapper = ref.read(receiptToFridgeItemMapperProvider);
    return mapper.map(extraction);
  }

  Future<bool> persistReviewedItems(List<FridgeItem> reviewedItems) async {
    try {
      final itemRepository = ref.read(fridgeItemRepositoryProvider);
      final storableItems = _storableItems(reviewedItems);
      final preparedItems = _prepareForBackfill(storableItems);
      final saved = await itemRepository.appendAll(preparedItems);
      if (saved) {
        await _enqueueMissingBarcodeRequests(preparedItems);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Receipt flow storage failed unexpectedly',
        name: 'ReceiptCaptureFlowController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  List<FridgeItem> _storableItems(List<FridgeItem> items) {
    return items
        .where((item) => item.canBeSavedToFridge)
        .toList(growable: false);
  }

  List<FridgeItem> _prepareForBackfill(List<FridgeItem> items) {
    final now = DateTime.now();
    return items
        .map((item) {
          if (item.normalizedBarcode != null) {
            return item;
          }
          return item.copyWith(
            barcodeLookupRequestedAt: item.barcodeLookupRequestedAt ?? now,
          );
        })
        .toList(growable: false);
  }

  Future<void> _enqueueMissingBarcodeRequests(List<FridgeItem> items) async {
    final flags = ref.read(barcodeBackfillFeatureFlagsProvider);
    if (!flags.enableQueueBackfill) {
      return;
    }

    final repository = ref.read(calorieBarcodeBackfillRepositoryProvider);
    final queuedFingerprints = <String>{};
    for (final item in items) {
      if (item.normalizedBarcode != null) {
        continue;
      }
      final fingerprint = item.resolvedFoodFingerprint;
      if (queuedFingerprints.contains(fingerprint)) {
        continue;
      }
      queuedFingerprints.add(fingerprint);
      await repository.enqueueFingerprintLookup(
        fingerprint: fingerprint,
        itemName: item.name,
        brand: item.brand,
        trigger: 'inventory_import',
      );
    }
  }
}
