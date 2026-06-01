import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Store hint for OFF product search.
String? productSearchHubSearchStore(ProductSearchHubRouteArgs args) {
  final item = args.item;
  if (!args.includeStoreInSearch || item == null) {
    return null;
  }

  final store = _supportedStore(item.storeName);
  return store ?? _supportedStore(item.brand);
}

/// Weight hint for OFF product search.
String? productSearchHubSearchWeight(ProductSearchHubRouteArgs args) {
  final item = args.item;
  if (!args.includeWeightInSearch || item == null) {
    return null;
  }
  return normalizeManualProductText(item.weight ?? '');
}

/// Initial text query shown when search is opened from an existing item.
String? productSearchHubInitialSearchQuery(ProductSearchHubRouteArgs args) {
  final item = args.item;
  if (item == null) {
    return null;
  }

  final parts = <String>[];
  final normalizedParts = <String>{};

  void addPart(String? value, {bool canBeBarcode = true}) {
    final normalized = normalizeManualProductText(value ?? '');
    if (normalized == null ||
        (!canBeBarcode && _looksLikeBarcodeText(normalized))) {
      return;
    }
    if (normalizedParts.add(normalized.toLowerCase())) {
      parts.add(normalized);
    }
  }

  addPart(item.ocrName ?? item.name, canBeBarcode: false);
  addPart(item.brand);
  if (!item.isManuallyAdded) {
    addPart(item.storeName);
  }
  return parts.isEmpty ? null : parts.join(' ');
}

String? _supportedStore(String? rawValue) {
  final normalized = normalizeStoreName(rawValue);
  return switch (normalized) {
    'Aldi' => 'Aldi',
    'Netto' => 'Netto',
    _ => null,
  };
}

bool _looksLikeBarcodeText(String value) {
  final normalized = normalizeBarcode(value);
  if (normalized.isEmpty) {
    return false;
  }
  final compact = value.replaceAll(RegExp(r'[\s-]+'), '');
  return compact == normalized;
}
