import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

/// Test fake for [ReceiptProductResolver].
class FakeReceiptProductResolver implements ReceiptProductResolver {
  final Map<String, List<ProductCandidate>> _candidatesByText = {};
  final Map<String, ProductCandidate> _productsByBarcode = {};
  final Map<String, List<ProductCandidate>> _candidatesByBarcode = {};
  final List<ProductCandidate> _catalog = [];

  /// If true, calls will throw an exception.
  bool shouldFail = false;

  /// Error message thrown when [shouldFail] is true.
  String failureMessage = 'Resolution failed';

  /// Registers candidates for a specific receipt raw text.
  void registerCandidatesForText(
    String rawText,
    List<ProductCandidate> candidates,
  ) {
    _candidatesByText[rawText.trim().toUpperCase()] = candidates;
  }

  /// Registers a product for a specific barcode.
  void registerProductForBarcode(
    String barcode,
    ProductCandidate product,
  ) {
    _productsByBarcode[barcode.trim()] = product;
    _candidatesByBarcode[barcode.trim()] = [product];
    if (!_catalog.contains(product)) {
      _catalog.add(product);
    }
  }

  /// Registers multiple candidates for a specific barcode.
  void registerCandidatesForBarcode(
    String barcode,
    List<ProductCandidate> candidates,
  ) {
    _candidatesByBarcode[barcode.trim()] = candidates;
    if (candidates.isNotEmpty) {
      _productsByBarcode[barcode.trim()] = candidates.first;
    }
    for (final c in candidates) {
      if (!_catalog.contains(c)) {
        _catalog.add(c);
      }
    }
  }

  /// Adds a product to the searchable catalog.
  void addToCatalog(ProductCandidate product) {
    if (!_catalog.contains(product)) {
      _catalog.add(product);
    }
  }

  @override
  Future<List<ProductCandidate>> resolveCandidates({
    required String rawLineText,
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    final normalized = rawLineText.trim().toUpperCase();
    return _candidatesByText[normalized] ?? const <ProductCandidate>[];
  }

  @override
  Future<Map<String, List<ProductCandidate>>> resolveBatch({
    required List<ReceiptLineItem> items,
    String? storeName,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    final result = <String, List<ProductCandidate>>{};
    for (final item in items) {
      result[item.id] = await resolveCandidates(
        rawLineText: item.rawName,
        storeName: storeName,
        brand: item.rawBrand,
        weight: item.packageWeight,
      );
    }
    return result;
  }

  @override
  Future<ProductCandidate?> resolveByBarcode(String barcode) async {
    if (shouldFail) throw Exception(failureMessage);
    return _productsByBarcode[barcode.trim()];
  }

  @override
  Future<List<ProductCandidate>> resolveCandidatesByBarcode(
    String barcode,
  ) async {
    if (shouldFail) throw Exception(failureMessage);
    final key = barcode.trim();
    if (_candidatesByBarcode.containsKey(key)) {
      return _candidatesByBarcode[key]!;
    }
    final single = _productsByBarcode[key];
    return single != null ? [single] : const <ProductCandidate>[];
  }

  @override
  Future<List<ProductCandidate>> searchByName(
    String query, {
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    final lowerQuery = query.toLowerCase();
    return _catalog
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
