import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/receipt_analysis_controller.dart';

class _FakeReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  _FakeReceiptAnalysisRepository({required this.onAnalyze});

  final Future<ReceiptAnalysisResult> Function(ReceiptInputSelection selection)
  onAnalyze;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) {
    return onAnalyze(selection);
  }
}

ReceiptInputSelection _selection() {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: 'receipt.pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

void main() {
  test('analysis success updates state with succeeded result', () async {
    final repository = _FakeReceiptAnalysisRepository(
      onAnalyze: (_) async => const ReceiptAnalysisResult.succeeded(
        rawResponse: '{}',
        extraction: ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[],
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptAnalysisRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptAnalysisControllerProvider.notifier)
        .analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.succeeded);
    expect(result, isA<ReceiptAnalysisSuccess>());
    expect(container.read(receiptAnalysisControllerProvider).value, result);
  });

  test('analysis failure result is passed through', () async {
    final repository = _FakeReceiptAnalysisRepository(
      onAnalyze: (_) async => const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.notImplemented,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptAnalysisRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptAnalysisControllerProvider.notifier)
        .analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.notImplemented);
    expect(container.read(receiptAnalysisControllerProvider).value, result);
  });

  test('analysis exception maps to unexpected failure', () async {
    final repository = _FakeReceiptAnalysisRepository(
      onAnalyze: (_) => throw Exception('boom'),
    );
    final container = ProviderContainer(
      overrides: [
        receiptAnalysisRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptAnalysisControllerProvider.notifier)
        .analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.unexpected);
    expect(container.read(receiptAnalysisControllerProvider).value, result);
  });
}
