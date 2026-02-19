import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

class _FakeTemplateConfigClient implements ReceiptTemplateConfigClient {
  _FakeTemplateConfigClient({required this.onLoadTemplateId});

  final Future<String> Function() onLoadTemplateId;

  @override
  Future<String> loadTemplateId() {
    return onLoadTemplateId();
  }
}

class _FakeTemplateModelClient implements ReceiptTemplateModelClient {
  _FakeTemplateModelClient({required this.onGenerateContent});

  final Future<String?> Function({
    required String templateId,
    required Map<String, Object?> inputs,
  })
  onGenerateContent;

  @override
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  }) {
    return onGenerateContent(templateId: templateId, inputs: inputs);
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
    name: 'receipt.jpg',
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

void main() {
  test('analyzeSelection returns succeeded with generated text', () async {
    final selection = _selection();
    String? capturedTemplateId;
    Map<String, Object?>? capturedInputs;

    final repository = DeviceReceiptAnalysisRepository(
      templateConfigClient: _FakeTemplateConfigClient(
        onLoadTemplateId: () async => 'receiptocr',
      ),
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          capturedTemplateId = templateId;
          capturedInputs = inputs;
          return '{"items": []}';
        },
      ),
      parser: _FakeReceiptAnalysisParser(
        onParse: (_) => const ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[],
        ),
      ),
    );

    final result = await repository.analyzeSelection(selection);

    expect(result.status, ReceiptAnalysisStatus.succeeded);
    final successResult = result as ReceiptAnalysisSuccess;
    expect(successResult.rawResponse, '{"items": []}');
    expect(capturedTemplateId, 'receiptocr');
    expect(capturedInputs?['mimeType'], selection.mimeType);
    expect(capturedInputs?['imageData'], base64Encode(selection.bytes));
  });

  test('analyzeSelection maps empty text to empty_response failure', () async {
    final repository = DeviceReceiptAnalysisRepository(
      templateConfigClient: _FakeTemplateConfigClient(
        onLoadTemplateId: () async => 'receiptocr',
      ),
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          return '   ';
        },
      ),
      parser: _FakeReceiptAnalysisParser(
        onParse: (_) => const ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[],
        ),
      ),
    );

    final result = await repository.analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.emptyResponse);
  });

  test(
    'analyzeSelection maps template config exception to config failure',
    () async {
      final repository = DeviceReceiptAnalysisRepository(
        templateConfigClient: _FakeTemplateConfigClient(
          onLoadTemplateId: () => throw Exception('rc failed'),
        ),
        templateModelClient: _FakeTemplateModelClient(
          onGenerateContent: ({required templateId, required inputs}) async {
            return '{"items": []}';
          },
        ),
        parser: _FakeReceiptAnalysisParser(
          onParse: (_) => const ReceiptAnalysisExtraction(
            root: <String, dynamic>{},
            items: <ReceiptAnalysisItem>[],
          ),
        ),
      );

      final result = await repository.analyzeSelection(_selection());

      expect(result.status, ReceiptAnalysisStatus.failed);
      expect(result.errorCode, ReceiptAnalysisErrorCodes.templateConfigFailed);
    },
  );

  test('analyzeSelection maps model exception to request failure', () async {
    final repository = DeviceReceiptAnalysisRepository(
      templateConfigClient: _FakeTemplateConfigClient(
        onLoadTemplateId: () async => 'receiptocr',
      ),
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) {
          throw Exception('ai failed');
        },
      ),
      parser: _FakeReceiptAnalysisParser(
        onParse: (_) => const ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[],
        ),
      ),
    );

    final result = await repository.analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.aiRequestFailed);
  });

  test('analyzeSelection maps parser exception to parse failure', () async {
    final repository = DeviceReceiptAnalysisRepository(
      templateConfigClient: _FakeTemplateConfigClient(
        onLoadTemplateId: () async => 'receiptocr',
      ),
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          return '{"items":[{"n":"Milk"}]}';
        },
      ),
      parser: _FakeReceiptAnalysisParser(
        onParse: (_) => throw const FormatException('invalid payload'),
      ),
    );

    final result = await repository.analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.parseFailed);
  });
}
