import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

void main() {
  test('succeeded result exposes success status and null error', () {
    const extraction = ReceiptAnalysisExtraction(
      root: <String, dynamic>{'store': 'Store'},
      items: <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Milk',
          rawPayload: <String, dynamic>{'n': 'Milk'},
        ),
      ],
    );
    const result = ReceiptAnalysisResult.succeeded(
      rawResponse: '{"i":[{"n":"Milk"}]}',
      extraction: extraction,
    );

    expect(result.status, ReceiptAnalysisStatus.succeeded);
    expect(result.isSuccess, isTrue);
    expect(result.errorCode, isNull);
  });

  test('failed result exposes failed status and error code', () {
    const result = ReceiptAnalysisResult.failed(errorCode: 'analysis_failed');

    expect(result.status, ReceiptAnalysisStatus.failed);
    expect(result.isSuccess, isFalse);
    expect(result.errorCode, 'analysis_failed');
  });
}
