import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

class _FakeReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  _FakeReceiptAnalysisRepository({required this.onAnalyzeSelection});

  final Future<ReceiptAnalysisResult> Function(ReceiptInputSelection selection)
  onAnalyzeSelection;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) {
    return onAnalyzeSelection(selection);
  }
}

ReceiptInputSelection _selectionWithName(String name) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

ReceiptAnalysisResult _successResult(String name) {
  return ReceiptAnalysisResult.succeeded(
    rawResponse: '{"items":[{"name":"$name"}]}',
    extraction: ReceiptAnalysisExtraction(
      root: <String, dynamic>{},
      items: <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: name,
          rawPayload: <String, dynamic>{'name': name},
        ),
      ],
    ),
  );
}

FridgeItem _mappedItem(String id) {
  return FridgeItem(
    id: id,
    name: id,
    entryDate: DateTime.parse('2026-02-26T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

void main() {
  test(
    'processSelections returns canceled when shouldContinue stops mid-batch',
    () async {
      var analyzeCalls = 0;
      var shouldContinueCalls = 0;
      final repository = _FakeReceiptAnalysisRepository(
        onAnalyzeSelection: (selection) async {
          analyzeCalls += 1;
          return _successResult(selection.name);
        },
      );
      final processor = ReceiptBatchProcessor(
        analysisRepository: repository,
        mapExtraction: (extraction) => <FridgeItem>[
          _mappedItem(extraction.items.first.name),
        ],
        loggerName: 'ReceiptBatchProcessorTest',
      );

      final result = await processor.processSelections(
        <ReceiptInputSelection>[
          _selectionWithName('a.jpg'),
          _selectionWithName('b.jpg'),
        ],
        shouldContinue: () {
          shouldContinueCalls += 1;
          return shouldContinueCalls < 3;
        },
      );

      expect(result.wasCanceled, isTrue);
      expect(analyzeCalls, 1);
      expect(result.progress.totalCount, 2);
      expect(result.progress.processedCount, 1);
      expect(result.progress.succeededCount, 1);
      expect(result.progress.failedCount, 0);
      expect(result.mappedItemsByIndex.keys, <int>[0]);
    },
  );

  test('processSelections runs analysis strictly sequential', () async {
    var currentConcurrency = 0;
    var maxConcurrency = 0;
    final order = <String>[];
    final repository = _FakeReceiptAnalysisRepository(
      onAnalyzeSelection: (selection) async {
        currentConcurrency += 1;
        if (currentConcurrency > maxConcurrency) {
          maxConcurrency = currentConcurrency;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
        order.add(selection.name);
        currentConcurrency -= 1;
        return _successResult(selection.name);
      },
    );
    final processor = ReceiptBatchProcessor(
      analysisRepository: repository,
      mapExtraction: (extraction) => <FridgeItem>[
        _mappedItem(extraction.items.first.name),
      ],
      loggerName: 'ReceiptBatchProcessorTest',
    );

    final result = await processor.processSelections(<ReceiptInputSelection>[
      _selectionWithName('a.jpg'),
      _selectionWithName('b.jpg'),
      _selectionWithName('c.jpg'),
    ], shouldContinue: () => true);

    expect(result.wasCanceled, isFalse);
    expect(maxConcurrency, 1);
    expect(order, <String>['a.jpg', 'b.jpg', 'c.jpg']);
    expect(result.progress.succeededCount, 3);
  });
}
