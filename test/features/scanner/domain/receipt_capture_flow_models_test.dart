import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';

ReceiptReviewItemDraft _draft() {
  return ReceiptReviewItemDraft(
    item: InventoryItem.create(
      id: 'food-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-20T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
    ),
  );
}

ReceiptAnalysisExtraction _extraction() {
  return const ReceiptAnalysisExtraction(
    root: <String, dynamic>{'store': 'Store'},
    items: <ReceiptAnalysisItem>[
      ReceiptAnalysisItem(
        name: 'Milk',
        rawPayload: <String, dynamic>{'n': 'M'},
      ),
    ],
  );
}

void main() {
  test('completed result exposes extraction and mapped items', () {
    final extraction = _extraction();
    final reviewDrafts = <ReceiptReviewItemDraft>[_draft()];
    final previewBytes = Uint8List.fromList(const <int>[1, 2, 3]);
    final result = ReceiptCaptureFlowResult.completed(
      source: ReceiptInputSource.file,
      extraction: extraction,
      reviewDrafts: reviewDrafts,
      receiptPreviewBytes: previewBytes,
    );

    expect(result.status, ReceiptCaptureFlowStatus.completed);
    expect(result.errorCode, isNull);
    expect(result.extraction, same(extraction));
    expect(result.reviewDrafts, equals(reviewDrafts));
    expect(result.receiptPreviewBytes, previewBytes);
    expect(result.isCompleted, isTrue);
  });

  test('inputCanceled result has no error, extraction or mapped items', () {
    const result = ReceiptCaptureFlowResult.inputCanceled(
      source: ReceiptInputSource.file,
    );

    expect(result.status, ReceiptCaptureFlowStatus.inputCanceled);
    expect(result.errorCode, isNull);
    expect(result.extraction, isNull);
    expect(result.reviewDrafts, isNull);
    expect(result.receiptPreviewBytes, isNull);
    expect(result.isCompleted, isFalse);
  });

  test('inputUnsupported result exposes error code only', () {
    const result = ReceiptCaptureFlowResult.inputUnsupported(
      source: ReceiptInputSource.camera,
      errorCode: 'unsupported',
    );

    expect(result.status, ReceiptCaptureFlowStatus.inputUnsupported);
    expect(result.errorCode, 'unsupported');
    expect(result.extraction, isNull);
    expect(result.reviewDrafts, isNull);
    expect(result.isCompleted, isFalse);
  });

  test('inputFailed result exposes error code only', () {
    const result = ReceiptCaptureFlowResult.inputFailed(
      source: ReceiptInputSource.file,
      errorCode: 'input_failed',
    );

    expect(result.status, ReceiptCaptureFlowStatus.inputFailed);
    expect(result.errorCode, 'input_failed');
    expect(result.extraction, isNull);
    expect(result.reviewDrafts, isNull);
    expect(result.isCompleted, isFalse);
  });

  test('analysisFailed result exposes error code only', () {
    const result = ReceiptCaptureFlowResult.analysisFailed(
      source: ReceiptInputSource.file,
      errorCode: 'analysis_failed',
    );

    expect(result.status, ReceiptCaptureFlowStatus.analysisFailed);
    expect(result.errorCode, 'analysis_failed');
    expect(result.extraction, isNull);
    expect(result.reviewDrafts, isNull);
    expect(result.isCompleted, isFalse);
  });

  test('batch progress counts succeeded and failed items', () {
    const progress = ReceiptBatchProgress(
      items: <ReceiptBatchItemProgress>[
        ReceiptBatchItemProgress(
          fileName: 'a.jpg',
          status: ReceiptBatchItemStatus.succeeded,
          reviewDraftCount: 2,
        ),
        ReceiptBatchItemProgress(
          fileName: 'b.jpg',
          status: ReceiptBatchItemStatus.failed,
          errorCode: 'analysis_failed',
        ),
        ReceiptBatchItemProgress(
          fileName: 'c.jpg',
          status: ReceiptBatchItemStatus.processing,
        ),
      ],
    );

    expect(progress.totalCount, 3);
    expect(progress.processedCount, 2);
    expect(progress.succeededCount, 1);
    expect(progress.failedCount, 1);
    expect(progress.hasSuccesses, isTrue);
    expect(progress.hasFailures, isTrue);
  });

  test('batch run result completed exposes mapped items', () {
    final reviewDrafts = <ReceiptReviewItemDraft>[_draft()];
    const progress = ReceiptBatchProgress(
      items: <ReceiptBatchItemProgress>[
        ReceiptBatchItemProgress(
          fileName: 'a.jpg',
          status: ReceiptBatchItemStatus.succeeded,
        ),
      ],
    );
    final result = ReceiptBatchRunResult.completed(
      progress: progress,
      reviewDrafts: reviewDrafts,
    );

    expect(result.status, ReceiptBatchRunStatus.completed);
    expect(result.progress.totalCount, 1);
    expect(result.reviewDrafts, reviewDrafts);
    expect(result.reviewDrafts, reviewDrafts);
    expect(result.errorCode, isNull);
  });

  test('batch run result inputFailed exposes error code', () {
    const result = ReceiptBatchRunResult.inputFailed(errorCode: 'input_failed');

    expect(result.status, ReceiptBatchRunStatus.inputFailed);
    expect(result.errorCode, 'input_failed');
    expect(result.reviewDrafts, isEmpty);
    expect(result.progress.totalCount, 0);
  });
}
