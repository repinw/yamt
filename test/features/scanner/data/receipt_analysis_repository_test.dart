import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

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
    name: 'receipt.pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

void main() {
  test('analyzeSelection returns succeeded with generated text', () async {
    final selection = _selection();
    String? capturedTemplateId;
    Map<String, Object?>? capturedInputs;

    final repository = DeviceReceiptAnalysisRepository(
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
    expect(capturedTemplateId, 'testtemplate');
    expect(capturedInputs?['mimeType'], selection.mimeType);
    expect(capturedInputs?['imageData'], base64Encode(selection.bytes));
  });

  test(
    'analyzeSelection loads bytes from filePath when selection bytes are empty',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'receipt-analysis-repo-test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final file = File('${tempDir.path}/receipt.pdf');
      final fileBytes = Uint8List.fromList(<int>[0x10, 0x20, 0x30]);
      await file.writeAsBytes(fileBytes);

      Map<String, Object?>? capturedInputs;
      final selection = ReceiptInputSelection(
        source: ReceiptInputSource.file,
        name: 'receipt.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List(0),
        filePath: file.path,
      );

      final repository = DeviceReceiptAnalysisRepository(
        templateModelClient: _FakeTemplateModelClient(
          onGenerateContent: ({required templateId, required inputs}) async {
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
      expect(capturedInputs?['imageData'], base64Encode(fileBytes));
    },
  );

  test(
    'analyzeSelection rejects oversized bytes before model request',
    () async {
      var modelCalled = false;
      final oversizedBytes = Uint8List((12 * 1024 * 1024) + 1);
      final repository = DeviceReceiptAnalysisRepository(
        templateModelClient: _FakeTemplateModelClient(
          onGenerateContent: ({required templateId, required inputs}) async {
            modelCalled = true;
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

      final result = await repository.analyzeSelection(
        ReceiptInputSelection(
          source: ReceiptInputSource.file,
          name: 'oversized.jpg',
          mimeType: 'image/jpeg',
          bytes: oversizedBytes,
        ),
      );

      expect(modelCalled, isFalse);
      expect(result.status, ReceiptAnalysisStatus.failed);
      expect(result.errorCode, ReceiptAnalysisErrorCodes.unexpected);
    },
  );

  test('analyzeSelection rejects heic input before model request', () async {
    var modelCalled = false;
    final repository = DeviceReceiptAnalysisRepository(
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          modelCalled = true;
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

    final result = await repository.analyzeSelection(
      ReceiptInputSelection(
        source: ReceiptInputSource.file,
        name: 'receipt.heic',
        mimeType: 'image/heic',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    expect(modelCalled, isFalse);
    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.unexpected);
  });

  test('analyzeSelection rejects corrupt image before model request', () async {
    var modelCalled = false;
    final repository = DeviceReceiptAnalysisRepository(
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          modelCalled = true;
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

    final result = await repository.analyzeSelection(
      ReceiptInputSelection(
        source: ReceiptInputSource.file,
        name: 'receipt.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList(utf8.encode('not an image file')),
      ),
    );

    expect(modelCalled, isFalse);
    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.unexpected);
  });

  test('analyzeSelection maps missing file to unexpected failure', () async {
    var modelCalled = false;
    final repository = DeviceReceiptAnalysisRepository(
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
          modelCalled = true;
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

    final missingPath =
        '${Directory.systemTemp.path}/'
        'yamt_missing_receipt_${DateTime.now().microsecondsSinceEpoch}.pdf';
    final result = await repository.analyzeSelection(
      ReceiptInputSelection(
        source: ReceiptInputSource.file,
        name: 'missing.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List(0),
        filePath: missingPath,
      ),
    );

    expect(modelCalled, isFalse);
    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.errorCode, ReceiptAnalysisErrorCodes.unexpected);
  });

  test('analyzeSelection downsizes image input before model request', () async {
    final sourceImage = img.Image(width: 2400, height: 1200)
      ..clear(img.ColorRgb8(255, 255, 255));
    final sourceBytes = Uint8List.fromList(img.encodePng(sourceImage));
    Map<String, Object?>? capturedInputs;
    final selection = ReceiptInputSelection(
      source: ReceiptInputSource.file,
      name: 'receipt.png',
      mimeType: 'image/png',
      bytes: sourceBytes,
    );

    final repository = DeviceReceiptAnalysisRepository(
      templateModelClient: _FakeTemplateModelClient(
        onGenerateContent: ({required templateId, required inputs}) async {
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
    expect(capturedInputs?['mimeType'], 'image/jpeg');
    final imageData = capturedInputs?['imageData'];
    expect(imageData, isA<String>());
    final uploadedBytes = base64Decode(imageData! as String);
    final uploadedImage = img.decodeImage(uploadedBytes);
    expect(uploadedImage, isNotNull);
    expect(uploadedImage!.width, 1800);
    expect(uploadedImage.height, 900);
  });

  test('analyzeSelection maps empty text to empty_response failure', () async {
    final repository = DeviceReceiptAnalysisRepository(
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

  test('analyzeSelection maps model exception to request failure', () async {
    final repository = DeviceReceiptAnalysisRepository(
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
