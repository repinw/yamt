import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/off_product_candidate_source.dart';
import 'package:yamt/features/inventory/data/off_selection_feedback_repository.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_review_state.dart';

part 'receipt_review_controller.g.dart';

/// Controller managing the receipt review flow and modifications.
@riverpod
class ReceiptReviewController extends _$ReceiptReviewController {
  @override
  ReceiptReviewState build(ScannedReceipt initialReceipt) {
    return ReceiptReviewState(receipt: initialReceipt);
  }

  /// Updates store name (e.g. if OCR misidentified store header).
  void updateStoreName(String newStoreName) {
    state = state.copyWith(
      receipt: state.receipt.copyWith(storeName: newStoreName),
    );
  }

  /// Updates receipt date and time.
  void updateDateTime(DateTime newDate) {
    state = state.copyWith(receipt: state.receipt.copyWith(dateTime: newDate));
  }

  /// Replaces an existing receipt line item completely
  /// (e.g. from item edit sheet).
  void updateItem(ReceiptLineItem updatedItem) {
    state = state.copyWith(receipt: state.receipt.updateItem(updatedItem));
  }

  /// Updates the quantity of a line item.
  void updateQuantity(String itemId, double newQuantity) {
    final item = _findItem(itemId);
    if (item == null) return;

    final updatedItem = item.copyWith(quantity: newQuantity);
    updateItem(updatedItem);
  }

  /// Updates the price of a line item.
  void updatePrice(String itemId, double newPrice) {
    final item = _findItem(itemId);
    if (item == null) return;

    final updatedItem = item.copyWith(totalPrice: newPrice);
    updateItem(updatedItem);
  }

  /// Assigns a specific product candidate to an item.
  void selectCandidate(String itemId, ProductCandidate candidate) {
    final item = _findItem(itemId);
    if (item == null) return;

    final updatedItem = item.withSelectedProduct(candidate);
    updateItem(updatedItem);
  }

  /// Clears the product mapping and resets item status to unmatched.
  void clearProduct(String itemId) {
    final item = _findItem(itemId);
    if (item == null) return;

    final updatedItem = item.clearProduct();
    updateItem(updatedItem);
  }

  /// Toggles whether an item is ignored.
  void toggleIgnore(String itemId) {
    final item = _findItem(itemId);
    if (item == null) return;

    final newStatus = item.status == ReceiptItemStatus.ignored
        ? (item.matchedProduct != null
              ? ReceiptItemStatus.confirmed
              : ReceiptItemStatus.unmatched)
        : ReceiptItemStatus.ignored;

    final updatedItem = item.copyWith(status: newStatus);
    updateItem(updatedItem);
  }

  /// Removes an item completely from the receipt.
  void removeItem(String itemId) {
    state = state.copyWith(receipt: state.receipt.removeItem(itemId));
  }

  /// Adds a manually created item to the receipt.
  void addItem(ReceiptLineItem item) {
    state = state.copyWith(receipt: state.receipt.addItem(item));
  }

  /// Confirms all items that currently have suggested products.
  void confirmAllSuggestions() {
    state = state.copyWith(receipt: state.receipt.confirmAllSuggestions());
  }

  /// Replaces an item's product using a scanned product barcode.
  Future<bool> replaceWithBarcode(String itemId, String barcode) async {
    final item = _findItem(itemId);
    if (item == null) return false;

    state = state.copyWith(isResolving: true, errorMessage: null);

    try {
      final resolver = ref.read(receiptProductResolverProvider);
      final product = await resolver.resolveByBarcode(barcode);

      if (!ref.mounted) return false;

      if (product == null) {
        state = state.copyWith(
          isResolving: false,
          errorMessage: 'Kein Produkt für Barcode $barcode gefunden.',
        );
        return false;
      }

      final updatedItem = item.withSelectedProduct(product);
      state = state.copyWith(
        isResolving: false,
        receipt: state.receipt.updateItem(updatedItem),
      );
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isResolving: false,
        errorMessage: 'Barcode-Suche fehlgeschlagen: $error',
      );
      return false;
    }
  }

  /// Searches catalog for candidate products matching [query].
  Future<List<ProductCandidate>> searchProducts(String query) async {
    final resolver = ref.read(receiptProductResolverProvider);
    return await resolver.searchByName(query);
  }

  /// Resolves candidate products matching [barcode] without auto-confirming.
  Future<List<ProductCandidate>> searchByBarcode(String barcode) async {
    final resolver = ref.read(receiptProductResolverProvider);
    return await resolver.resolveCandidatesByBarcode(barcode);
  }

  /// Saves the entire receipt with all confirmed items to inventory.
  Future<bool> saveReceipt() async {
    if (!state.receipt.isReadyToSave) {
      state = state.copyWith(
        errorMessage:
            'Bitte alle offenen Positionen bestätigen oder ignorieren.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final gateway = ref.read(receiptStorageGatewayProvider);
      final savable = state.receipt.savableItems;

      await gateway.saveReceipt(receipt: state.receipt, items: savable);

      if (!ref.mounted) return false;
      unawaited(
        ref
            .read(offSelectionFeedbackRepositoryProvider)
            .report(_selectionFeedback(savable)),
      );

      state = state.copyWith(isSaving: false, saveSuccess: true);
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Fehler beim Speichern des Belegs: $error',
      );
      return false;
    }
  }

  /// Clears current error message.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// The products picked for [items], as the search saw each line.
  List<OffSelectionFeedback> _selectionFeedback(List<ReceiptLineItem> items) {
    final storeName = state.receipt.storeName;
    final feedback = <OffSelectionFeedback>[];
    for (final item in items) {
      final code = item.matchedProduct?.barcode?.trim() ?? '';
      final line = item.rawName.trim();
      if (!_isBarcode(code) || line.isEmpty) continue;
      final rank = item.candidates.indexWhere(
        (candidate) => candidate.barcode?.trim() == code,
      );
      feedback.add(
        OffSelectionFeedback(
          receiptLine: line,
          code: code,
          store: offSearchStoreFor(storeName: storeName, brand: item.rawBrand),
          brand: item.rawBrand?.trim(),
          weight: item.packageWeight?.trim(),
          rank: rank < 0 ? null : rank,
        ),
      );
    }
    return feedback;
  }

  static bool _isBarcode(String code) =>
      code.isNotEmpty && RegExp(r'^\d+$').hasMatch(code);

  ReceiptLineItem? _findItem(String itemId) {
    return state.receipt.items
        .where((element) => element.id == itemId)
        .firstOrNull;
  }
}
