/// Parsed serving quantity and unit.
typedef OffProductParsedServing = ({double quantity, String unit});

/// Resolved package weight and serving info.
typedef OffProductResolvedServing = ({
  String? packageWeight,
  String? servingSize,
  double? servingQuantity,
  String? servingQuantityUnit,
});

/// Helper resolving package weight and serving size for OFF search results.
class OffProductSearchPackageWeightResolver {
  /// Creates an OFF package weight resolver.
  const OffProductSearchPackageWeightResolver();

  /// Resolves package weight and serving info directly from an item payload.
  OffProductResolvedServing resolveFromItem(Map<String, dynamic> item) {
    final rawWeight = _readText(
      item['weight'] ?? item['package_weight'] ?? item['quantity'],
    );
    final prodQty = _readDouble(
      item['product_quantity'] ?? item['productQuantity'],
    );
    final prodUnit = _readText(
      item['product_quantity_unit'] ?? item['productQuantityUnit'],
    );
    final sSize = _readText(item['serving_size'] ?? item['servingSize']);
    var sQty = _readDouble(
      item['serving_quantity'] ?? item['servingQuantity'],
    );
    var sUnit = _readText(
      item['serving_quantity_unit'] ?? item['servingQuantityUnit'],
    );

    if ((sQty == null || sUnit == null) && sSize != null) {
      final parsed = parseServingSize(sSize);
      if (parsed != null) {
        sQty ??= parsed.quantity;
        sUnit ??= parsed.unit;
      }
    }

    final pkgWeight = resolvePackageWeight(
      rawWeight: rawWeight,
      productQuantity: prodQty,
      productQuantityUnit: prodUnit,
      servingSize: sSize,
      servingQuantity: sQty,
      servingQuantityUnit: sUnit,
    );

    return (
      packageWeight: pkgWeight,
      servingSize: sSize,
      servingQuantity: sQty,
      servingQuantityUnit: sUnit,
    );
  }

  /// Resolves the effective package weight string from available
  /// product attributes.
  String? resolvePackageWeight({
    required String? rawWeight,
    required double? productQuantity,
    required String? productQuantityUnit,
    required String? servingSize,
    required double? servingQuantity,
    required String? servingQuantityUnit,
  }) {
    if (rawWeight != null && rawWeight.isNotEmpty) {
      final isTrivialPiece = RegExp(
        r'^\s*1\s*(?:st(?:k|ück|ueck)?\.?|pcs?|pieces?|portion)?\s*$',
        caseSensitive: false,
      ).hasMatch(rawWeight);
      if (isTrivialPiece &&
          productQuantity != null &&
          productQuantity > 0 &&
          productQuantityUnit != null &&
          productQuantityUnit.isNotEmpty) {
        return '${formatQuantity(productQuantity)} $productQuantityUnit';
      }
      return rawWeight;
    }

    if (productQuantity != null && productQuantity > 0) {
      final unit = productQuantityUnit?.trim();
      final qtyStr = formatQuantity(productQuantity);
      if (unit != null && unit.isNotEmpty) {
        return '$qtyStr $unit';
      }
      return qtyStr;
    }

    if (servingQuantity != null && servingQuantity > 0) {
      final unit = servingQuantityUnit?.trim();
      final qtyStr = formatQuantity(servingQuantity);
      if (unit != null && unit.isNotEmpty) {
        return '$qtyStr $unit';
      }
      return qtyStr;
    }

    if (servingSize != null && servingSize.trim().isNotEmpty) {
      return servingSize.trim();
    }

    return null;
  }

  /// Parses a serving size string into a quantity and unit pair.
  OffProductParsedServing? parseServingSize(String servingSize) {
    final trimmed = servingSize.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parenthesized = RegExp(r'\(([^)]+)\)').allMatches(trimmed);
    for (final match in parenthesized) {
      final inner = match.group(1);
      if (inner != null) {
        final parsedInner = extractQuantityAndUnit(inner);
        if (parsedInner != null) {
          return parsedInner;
        }
      }
    }

    return extractQuantityAndUnit(trimmed);
  }

  /// Extracts quantity and unit from text like "125 g" or "330ml".
  OffProductParsedServing? extractQuantityAndUnit(String text) {
    final match = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*([a-zA-ZäöüÄÖÜß]+(?:\.[a-zA-ZäöüÄÖÜß]+)?)',
    ).firstMatch(text);
    if (match == null) {
      return null;
    }

    final qtyStr = match.group(1)?.replaceAll(',', '.');
    final unitStr = match.group(2)?.trim();
    if (qtyStr == null || unitStr == null || unitStr.isEmpty) {
      return null;
    }

    final qty = double.tryParse(qtyStr);
    if (qty == null) {
      return null;
    }

    return (quantity: qty, unit: unitStr);
  }

  /// Formats a quantity double without trailing decimals when whole.
  String formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String? _readText(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw.replaceAll(',', '.'));
  }
}
