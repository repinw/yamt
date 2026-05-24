import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_resolution_service.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

part 'receipt_capture_flow_controller.g.dart';

/// Defines receipt capture flow controller.
@Riverpod(
  dependencies: [receiptReviewResolutionService, receiptCameraSupported],
)
class ReceiptCaptureFlowController extends _$ReceiptCaptureFlowController {
  Future<ReceiptCaptureFlowResult>? _activeRun;

  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  /// Run.
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

  /// Run selection.
  Future<ReceiptCaptureFlowResult> runSelection({
    required ReceiptInputSelection selection,
  }) async {
    final inFlight = _activeRun;
    if (inFlight != null) {
      return inFlight;
    }

    final operation = _runSelectionInternal(selection: selection);
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

    final pickStopwatch = Stopwatch()..start();
    final inputResult = await _pickInput(source);
    pickStopwatch.stop();
    _debugLogReceiptFlowTiming('input pick', pickStopwatch.elapsed, source);
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

  Future<ReceiptCaptureFlowResult> _runSelectionInternal({
    required ReceiptInputSelection selection,
  }) async {
    state = const AsyncLoading();
    return _analyzeSelection(source: selection.source, selection: selection);
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
    final totalStopwatch = Stopwatch()..start();
    try {
      final analysisRepository = ref.read(receiptAnalysisRepositoryProvider);
      final analysisStopwatch = Stopwatch()..start();
      final analysisResult = await analysisRepository.analyzeSelection(
        selection,
      );
      analysisStopwatch.stop();
      _debugLogReceiptFlowTiming(
        'analysis',
        analysisStopwatch.elapsed,
        source,
      );
      if (!ref.mounted) {
        return ReceiptCaptureFlowResult.analysisFailed(
          source: source,
          errorCode: ReceiptAnalysisErrorCodes.unexpected,
        );
      }

      switch (analysisResult) {
        case ReceiptAnalysisSuccess(:final extraction):
          final draftStopwatch = Stopwatch()..start();
          final reviewDrafts = await _prepareReviewDrafts(extraction);
          draftStopwatch.stop();
          _debugLogReceiptFlowTiming(
            'draft prep',
            draftStopwatch.elapsed,
            source,
            itemCount: reviewDrafts.length,
          );
          totalStopwatch.stop();
          _debugLogReceiptFlowTiming(
            'total',
            totalStopwatch.elapsed,
            source,
            itemCount: reviewDrafts.length,
          );
          return _setAndReturn(
            ReceiptCaptureFlowResult.completed(
              source: source,
              extraction: extraction,
              reviewDrafts: reviewDrafts,
              receiptPreviewBytes: selection.bytes,
            ),
          );
        case ReceiptAnalysisFailure(:final errorCode):
          totalStopwatch.stop();
          _debugLogReceiptFlowTiming(
            'failed total',
            totalStopwatch.elapsed,
            source,
          );
          return _setAndReturn(
            ReceiptCaptureFlowResult.analysisFailed(
              source: source,
              errorCode: errorCode,
            ),
          );
      }
    } on Object catch (error, stackTrace) {
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

  Future<List<ReceiptReviewItemDraft>> _prepareReviewDrafts(
    ReceiptAnalysisExtraction extraction,
  ) {
    final resolutionService = ref.read(receiptReviewResolutionServiceProvider);
    return resolutionService.prepareDrafts(extraction);
  }

  /// Persist reviewed items.
  Future<bool> persistReviewedItems(
    List<ReceiptReviewItemDraft> reviewedItems,
  ) async {
    try {
      final resolutionService = ref.read(
        receiptReviewResolutionServiceProvider,
      );
      final result = await resolutionService.persistReviewedItems(
        reviewedItems,
      );
      return result.saved;
    } on Object catch (error, stackTrace) {
      log(
        'Receipt flow storage failed unexpectedly',
        name: 'ReceiptCaptureFlowController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

void _debugLogReceiptFlowTiming(
  String stage,
  Duration elapsed,
  ReceiptInputSource source, {
  int? itemCount,
}) {
  assert(() {
    final itemSuffix = itemCount == null ? '' : ', items: $itemCount';
    log(
      'Receipt ${source.name} flow $stage took '
      '${elapsed.inMilliseconds}ms$itemSuffix.',
      name: 'ReceiptCaptureFlowController',
    );
    return true;
  }(), 'Receipt flow timing log should run only in debug mode.');
}
