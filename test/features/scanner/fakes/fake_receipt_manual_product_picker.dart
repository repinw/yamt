import 'package:flutter/material.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';

/// Test fake for [ReceiptManualProductPicker].
class FakeReceiptManualProductPicker implements ReceiptManualProductPicker {
  /// The canned candidate to return when [pickOrEditProduct] is called.
  ProductCandidate? nextResult;

  /// Recorded initial queries.
  final List<String> recordedQueries = [];

  /// Recorded barcodes.
  final List<String?> recordedBarcodes = [];

  /// Recorded raw names.
  final List<String?> recordedRawNames = [];

  /// Recorded receipt stores.
  final List<String?> recordedStoreNames = [];

  /// Recorded receipt brands.
  final List<String?> recordedBrands = [];

  /// Recorded package weights.
  final List<String?> recordedWeights = [];

  @override
  Future<ProductCandidate?> pickOrEditProduct(
    BuildContext context, {
    required String initialQuery,
    String? barcode,
    String? rawName,
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    recordedQueries.add(initialQuery);
    recordedBarcodes.add(barcode);
    recordedRawNames.add(rawName);
    recordedStoreNames.add(storeName);
    recordedBrands.add(brand);
    recordedWeights.add(weight);
    return nextResult;
  }

  @override
  Future<ProductCandidate?> createCustomProduct(
    BuildContext context, {
    String? barcode,
    String? initialName,
  }) async {
    recordedQueries.add(initialName ?? '');
    recordedBarcodes.add(barcode);
    return nextResult;
  }
}
