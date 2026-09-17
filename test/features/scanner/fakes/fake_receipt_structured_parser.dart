import 'package:yamt/features/scanner/domain/contracts/receipt_structured_parser.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Test fake for [ReceiptStructuredParser].
class FakeReceiptStructuredParser implements ReceiptStructuredParser {
  /// Preconfigured receipt returned on next call.
  ScannedReceipt nextReceipt = const ScannedReceipt(
    id: 'fake-receipt-id',
    storeName: 'REWE',
    printedTotal: 3.48,
    rawText: 'REWE\nItem 1\nItem 2',
  );

  /// If true, calls will throw an exception.
  bool shouldFail = false;

  /// Error message thrown when [shouldFail] is true.
  String failureMessage = 'Parsing failed';

  /// History of raw texts passed to [parseRawText].
  final List<String> parsedRawTextsHistory = <String>[];

  /// History of source file paths passed to [parseRawText].
  final List<List<String>> sourceFilePathsHistory = <List<String>>[];

  /// History of PDF file paths passed to [parsePdf].
  final List<String> parsedPdfPathsHistory = <String>[];

  @override
  Future<ScannedReceipt> parseRawText({
    required String rawText,
    List<String> sourceFilePaths = const <String>[],
  }) async {
    parsedRawTextsHistory.add(rawText);
    sourceFilePathsHistory.add(List<String>.unmodifiable(sourceFilePaths));

    if (shouldFail) {
      throw Exception(failureMessage);
    }

    return nextReceipt.copyWith(
      rawText: rawText,
      sourceFilePaths: sourceFilePaths,
    );
  }

  @override
  Future<ScannedReceipt> parsePdf({required String pdfFilePath}) async {
    parsedPdfPathsHistory.add(pdfFilePath);

    if (shouldFail) {
      throw Exception(failureMessage);
    }

    return nextReceipt.copyWith(sourceFilePaths: <String>[pdfFilePath]);
  }
}
