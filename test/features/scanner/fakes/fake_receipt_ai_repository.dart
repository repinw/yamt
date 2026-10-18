import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Test fake for [ReceiptAiRepository].
class FakeReceiptAiRepository implements ReceiptAiRepository {
  /// Receipt returned by the next call.
  ScannedReceipt nextReceipt = const ScannedReceipt(
    id: 'fake-receipt-id',
    storeName: 'REWE',
    printedTotal: 3.48,
  );

  /// If true, calls throw an exception.
  bool shouldFail = false;

  /// When set, [parseReceipt] waits for it before it answers.
  Future<void>? gate;

  /// File paths of every [parseReceipt] call.
  final List<List<String>> parsedPathsHistory = <List<String>>[];

  @override
  Future<ScannedReceipt> parseReceipt(List<String> filePaths) async {
    parsedPathsHistory.add(List<String>.unmodifiable(filePaths));
    await gate;
    if (shouldFail) {
      throw Exception('Parsing failed');
    }
    return nextReceipt.copyWith(sourceFilePaths: filePaths);
  }
}
