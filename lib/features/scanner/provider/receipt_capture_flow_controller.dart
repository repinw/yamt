import 'dart:async';
import 'dart:developer' show log;

import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

part 'receipt_capture_flow_controller.g.dart';

@riverpod
class ReceiptCaptureFlowController extends _$ReceiptCaptureFlowController {
  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  Future<ReceiptCaptureFlowResult> run({
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

  Future<ReceiptBatchRunResult> runFileBatch() async {
    state = const AsyncLoading();

    final inputRepository = ref.read(receiptInputRepositoryProvider);
    final inputResult = await inputRepository.pickFromFiles();
    if (!ref.mounted) {
      return ReceiptBatchRunResult.inputFailed(
        errorCode: _inputUnexpectedCode(ReceiptInputSource.file),
      );
    }

    switch (inputResult.status) {
      case ReceiptInputBatchStatus.selected:
        return _runSelectedBatch(selections: inputResult.selections);
      case ReceiptInputBatchStatus.canceled:
        _setAndReturn(
          const ReceiptCaptureFlowResult.inputCanceled(
            source: ReceiptInputSource.file,
          ),
        );
        return const ReceiptBatchRunResult.inputCanceled();
      case ReceiptInputBatchStatus.failed:
        final errorCode =
            inputResult.errorCode ??
            _inputUnexpectedCode(ReceiptInputSource.file);
        _setAndReturn(
          ReceiptCaptureFlowResult.inputFailed(
            source: ReceiptInputSource.file,
            errorCode: errorCode,
          ),
        );
        return ReceiptBatchRunResult.inputFailed(errorCode: errorCode);
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

  Future<ReceiptBatchRunResult> _runSelectedBatch({
    required List<ReceiptInputSelection> selections,
  }) async {
    final batchProcessor = _batchProcessor();
    final result = await batchProcessor.processSelections(
      selections,
      shouldContinue: () => ref.mounted,
    );
    if (!ref.mounted || result.wasCanceled) {
      return ReceiptBatchRunResult.inputFailed(
        errorCode: _inputUnexpectedCode(ReceiptInputSource.file),
      );
    }

    if (ref.mounted) {
      state = const AsyncData(null);
    }
    return ReceiptBatchRunResult.completed(
      progress: result.progress,
      mappedItems: result.mappedItems,
    );
  }

  ReceiptBatchProcessor _batchProcessor() {
    final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
    final mapper = ref.read(receiptToFridgeItemMapperProvider);
    return ReceiptBatchProcessor(
      analysisRepository: analysisRepository,
      mapExtraction: mapper.map,
      loggerName: 'ReceiptCaptureFlowController',
    );
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
      final saved = await itemRepository.appendAll(storableItems);
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
}
