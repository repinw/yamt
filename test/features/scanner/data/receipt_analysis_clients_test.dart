import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_clients.dart';
import 'package:yamt/features/settings/provider/ai_processing_level_controller.dart';

void main() {
  test('minimal processing level uses receiptocr-minimal template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.minimal,
    );

    expect(await client.loadTemplateId(), 'receiptocr-minimal');
  });

  test('low processing level uses receiptocr-low template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.low,
    );

    expect(await client.loadTemplateId(), 'receiptocr-low');
  });

  test('balanced processing level uses receiptocr-medium template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.balanced,
    );

    expect(await client.loadTemplateId(), 'receiptocr-medium');
  });

  test('high processing level uses receiptocr-high template', () async {
    final client = StaticReceiptTemplateConfigClient(
      level: AiProcessingLevel.high,
    );

    expect(await client.loadTemplateId(), 'receiptocr-high');
  });
}
