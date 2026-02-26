import 'dart:developer' show log;

import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

typedef ReceiptExtractionMapper =
    List<FridgeItem> Function(ReceiptAnalysisExtraction extraction);

class ReceiptBatchProcessResult {
  const ReceiptBatchProcessResult({
    required this.progress,
    required this.mappedItemsByIndex,
    required this.wasCanceled,
  });

  final ReceiptBatchProgress progress;
  final Map<int, List<FridgeItem>> mappedItemsByIndex;
  final bool wasCanceled;

  bool get hasMappedItems =>
      mappedItemsByIndex.values.any((items) => items.isNotEmpty);

  List<FridgeItem> get mappedItems => mappedItemsByIndex.values
      .expand((items) => items)
      .toList(growable: false);
}

class ReceiptBatchProcessor {
  const ReceiptBatchProcessor({
    required ReceiptAnalysisRepository analysisRepository,
    required ReceiptExtractionMapper mapExtraction,
    required this.loggerName,
  }) : _analysisRepository = analysisRepository,
       _mapExtraction = mapExtraction;

  final ReceiptAnalysisRepository _analysisRepository;
  final ReceiptExtractionMapper _mapExtraction;
  final String loggerName;

  Future<ReceiptBatchProcessResult> processSelections(
    List<ReceiptInputSelection> selections, {
    required bool Function() shouldContinue,
    void Function(ReceiptBatchProgress progress)? onProgressChanged,
    void Function(
      int index,
      List<FridgeItem> mappedItems,
      ReceiptBatchProgress progress,
    )?
    onItemSucceeded,
    void Function(int index, ReceiptBatchProgress progress)? onItemFailed,
  }) async {
    var progress = _queuedBatchProgress(selections);
    var mappedItemsByIndex = <int, List<FridgeItem>>{};
    onProgressChanged?.call(progress);

    for (var index = 0; index < selections.length; index++) {
      if (!shouldContinue()) {
        return ReceiptBatchProcessResult(
          progress: progress,
          mappedItemsByIndex: mappedItemsByIndex,
          wasCanceled: true,
        );
      }

      progress = _updateBatchItem(
        progress: progress,
        index: index,
        status: ReceiptBatchItemStatus.processing,
        clearErrorCode: true,
      );
      onProgressChanged?.call(progress);

      // Keep processing sequential to avoid API bursts and memory spikes.
      final analysis = await _analyzeSelection(selections[index]);
      if (!shouldContinue()) {
        return ReceiptBatchProcessResult(
          progress: progress,
          mappedItemsByIndex: mappedItemsByIndex,
          wasCanceled: true,
        );
      }

      if (analysis.errorCode == null) {
        mappedItemsByIndex = <int, List<FridgeItem>>{
          ...mappedItemsByIndex,
          index: analysis.mappedItems,
        };
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.succeeded,
          mappedItemCount: analysis.mappedItems.length,
          clearErrorCode: true,
        );
        onItemSucceeded?.call(index, analysis.mappedItems, progress);
      } else {
        progress = _updateBatchItem(
          progress: progress,
          index: index,
          status: ReceiptBatchItemStatus.failed,
          errorCode: analysis.errorCode,
          mappedItemCount: 0,
        );
        onItemFailed?.call(index, progress);
      }
    }

    return ReceiptBatchProcessResult(
      progress: progress,
      mappedItemsByIndex: mappedItemsByIndex,
      wasCanceled: false,
    );
  }

  Future<({List<FridgeItem> mappedItems, String? errorCode})> _analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    try {
      final analysisResult = await _analysisRepository.analyzeSelection(
        selection,
      );
      return switch (analysisResult) {
        ReceiptAnalysisSuccess(:final extraction) => (
          mappedItems: _mapExtraction(extraction),
          errorCode: null,
        ),
        ReceiptAnalysisFailure(:final errorCode) => (
          mappedItems: const <FridgeItem>[],
          errorCode: errorCode,
        ),
      };
    } catch (error, stackTrace) {
      log(
        'Receipt batch analysis failed for ${selection.name}',
        name: loggerName,
        error: error,
        stackTrace: stackTrace,
      );
      return (
        mappedItems: const <FridgeItem>[],
        errorCode: ReceiptAnalysisErrorCodes.unexpected,
      );
    }
  }

  ReceiptBatchProgress _queuedBatchProgress(
    List<ReceiptInputSelection> selections,
  ) {
    return ReceiptBatchProgress(
      items: selections
          .map(
            (selection) => ReceiptBatchItemProgress(
              fileName: selection.name,
              status: ReceiptBatchItemStatus.queued,
            ),
          )
          .toList(growable: false),
    );
  }

  ReceiptBatchProgress _updateBatchItem({
    required ReceiptBatchProgress progress,
    required int index,
    required ReceiptBatchItemStatus status,
    String? errorCode,
    bool clearErrorCode = false,
    int? mappedItemCount,
  }) {
    final currentItem = progress.items[index];
    final updatedItem = currentItem.copyWith(
      status: status,
      errorCode: errorCode,
      clearErrorCode: clearErrorCode,
      mappedItemCount: mappedItemCount,
    );
    return progress.updateItem(index, updatedItem);
  }
}
