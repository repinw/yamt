import 'package:yamt/features/scanner/domain/contracts/receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Eine kontrollierte Fake-Implementierung von [ReceiptStorageGateway]
/// für Tests.
class FakeReceiptStorageGateway implements ReceiptStorageGateway {
  /// Alle gespeicherten Belege mit ihren übergebenen Artikeln.
  final List<({ScannedReceipt receipt, List<ReceiptLineItem> items})>
  savedReceipts = [];

  /// Alle gelernten Alias-Zuordnungen.
  final List<({String rawText, String productId, String? storeName})>
  learnedAliases = [];

  /// Simulierter Fehler beim Speichern (falls gesetzt).
  Exception? errorToThrowOnSave;

  @override
  Future<void> saveReceipt({
    required ScannedReceipt receipt,
    required List<ReceiptLineItem> items,
  }) async {
    if (errorToThrowOnSave != null) {
      throw errorToThrowOnSave!;
    }
    savedReceipts.add((receipt: receipt, items: items));
  }

  @override
  Future<void> learnAlias({
    required String rawLineText,
    required String productId,
    String? storeName,
  }) async {
    learnedAliases.add((
      rawText: rawLineText,
      productId: productId,
      storeName: storeName,
    ));
  }
}
