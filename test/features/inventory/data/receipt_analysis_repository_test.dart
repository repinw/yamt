import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_repository.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

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
    );

    final result = await repository.analyzeSelection(selection);

    expect(result.status, ReceiptAnalysisStatus.succeeded);
    expect(result.rawResponse, '{"items": []}');
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
    );

    final result = await repository.analyzeSelection(_selection());

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.aiRequestFailed);
  });
}
