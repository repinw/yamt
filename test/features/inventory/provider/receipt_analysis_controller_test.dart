import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_parser.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_repository.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';
import 'package:yamt/features/inventory/provider/receipt_analysis_controller.dart';

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

class _FakeReceiptAnalysisParser implements ReceiptAnalysisParser {
  _FakeReceiptAnalysisParser({required this.onParse});

  final ReceiptAnalysisExtraction Function(String rawResponse) onParse;

  @override
  ReceiptAnalysisExtraction parse(String rawResponse) {
    return onParse(rawResponse);
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
      onAnalyze: (_) async =>
          const ReceiptAnalysisResult.succeeded(rawResponse: '{}'),
    );
    final parser = _FakeReceiptAnalysisParser(
      onParse: (_) => const ReceiptAnalysisExtraction(
        root: <String, dynamic>{},
        items: <Map<String, dynamic>>[],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        receiptAnalysisRepositoryProvider.overrideWithValue(repository),
        receiptAnalysisParserProvider.overrideWithValue(parser),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptAnalysisControllerProvider.notifier)
        .analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.succeeded);
    expect(result.extraction, isNotNull);
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

  test('analysis parse failure maps to parse_failed result', () async {
    final repository = _FakeReceiptAnalysisRepository(
      onAnalyze: (_) async => const ReceiptAnalysisResult.succeeded(
        rawResponse: '{"items":[{"name":"milk"}]}',
      ),
    );
    final parser = _FakeReceiptAnalysisParser(
      onParse: (_) => throw const FormatException('bad json shape'),
    );
    final container = ProviderContainer(
      overrides: [
        receiptAnalysisRepositoryProvider.overrideWithValue(repository),
        receiptAnalysisParserProvider.overrideWithValue(parser),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptAnalysisControllerProvider.notifier)
        .analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.parseFailed);
    expect(container.read(receiptAnalysisControllerProvider).value, result);
  });
}
