import 'package:yamt/features/scanner/domain/contracts/receipt_text_extractor.dart';

/// Test fake for [ReceiptTextExtractor].
class FakeReceiptTextExtractor implements ReceiptTextExtractor {
  /// Preconfigured text returned on next call.
  String nextRawText =
      'REWE Markt GmbH\n'
      'Vollmilch 3.8% 1L       1.49 EUR\n'
      'Bananen 1kg             1.99 EUR\n'
      'SUMME                   3.48 EUR\n';

  /// If true, calls will throw an exception.
  bool shouldFail = false;

  /// Error message thrown when [shouldFail] is true.
  String failureMessage = 'Extraction failed';

  /// History of file path lists passed to [extractText].
  final List<List<String>> extractedPathsHistory = <List<String>>[];

  @override
  Future<String> extractText(List<String> filePaths) async {
    extractedPathsHistory.add(List<String>.unmodifiable(filePaths));

    if (shouldFail) {
      throw Exception(failureMessage);
    }

    return nextRawText;
  }

  @override
  Future<void> dispose() async {}
}
