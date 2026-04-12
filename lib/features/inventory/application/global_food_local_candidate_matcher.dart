part of 'global_food_item_matcher.dart';

const int _globalFoodQueryTokenLimit = 10;

class _GlobalFoodLocalCandidateMatcher {
  const _GlobalFoodLocalCandidateMatcher();

  _LocalMatchInput buildLocalMatchInput(InventoryItem item) {
    final normalizedName = normalizeGlobalFoodText(item.name);
    final normalizedBrand = normalizeGlobalFoodText(item.brand ?? '');
    final normalizedCategory = normalizeGlobalFoodText(item.category ?? '');
    final normalizedStoreName = normalizeGlobalFoodText(
      normalizeStoreName(item.storeName) ?? '',
    );
    final foodFingerprint = _queryFoodFingerprintFor(item);
    final tokens = _queryNameTokensFor(item.name);
    return _LocalMatchInput(
      normalizedName: normalizedName,
      normalizedBrand: normalizedBrand,
      normalizedCategory: normalizedCategory,
      normalizedStoreName: normalizedStoreName,
      foodFingerprint: foodFingerprint,
      nameTokens: tokens,
      nameTokenSet: tokens.toSet(),
      barcode: item.normalizedBarcode,
    );
  }

  static _GlobalFoodMatcherQuery? buildQuery(_LocalMatchInput localMatchInput) {
    final normalizedName = localMatchInput.normalizedName;
    final searchTokens = localMatchInput.nameTokens;
    final barcode = localMatchInput.barcode;
    final foodFingerprint = localMatchInput.foodFingerprint;
    final hasQuery =
        normalizedName.isNotEmpty ||
        searchTokens.isNotEmpty ||
        barcode != null ||
        foodFingerprint != null;
    if (!hasQuery) {
      return null;
    }

    return _GlobalFoodMatcherQuery(
      normalizedName: normalizedName.isEmpty ? null : normalizedName,
      normalizedStoreName: localMatchInput.normalizedStoreName.isEmpty
          ? null
          : localMatchInput.normalizedStoreName,
      barcode: barcode,
      foodFingerprint: foodFingerprint,
      searchTokens: searchTokens,
    );
  }

  List<GlobalFoodMatchCandidate> scoreCandidates(
    _LocalMatchInput item,
    Iterable<GlobalFoodItem> products,
  ) {
    return products
        .map((product) => _scoreCandidate(item, product))
        .whereType<GlobalFoodMatchCandidate>()
        .toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));
  }

  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    final best = candidates.first;
    return switch (best.reason) {
      GlobalFoodMatchReason.receiptAliasExact => best.item.id,
      GlobalFoodMatchReason.fingerprintExact => best.item.id,
      GlobalFoodMatchReason.nameBrandStrong =>
        _hasConfidentLead(candidates) ? best.item.id : null,
      GlobalFoodMatchReason.nameExact =>
        candidates.length == 1 ? best.item.id : null,
      GlobalFoodMatchReason.nameTokenMatch ||
      GlobalFoodMatchReason.externalSearch => null,
    };
  }

  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return false;
    }
    return defaultSelectionFor(candidates) == null;
  }

  GlobalFoodMatchCandidate? _scoreCandidate(
    _LocalMatchInput item,
    GlobalFoodItem product,
  ) {
    if (product.status == GlobalFoodItemStatus.merged) {
      return null;
    }

    var score = 0.0;
    var reason = GlobalFoodMatchReason.nameTokenMatch;
    final itemFingerprint = item.foodFingerprint;
    if (product.resolvedFoodFingerprint == itemFingerprint) {
      score += 100;
      reason = GlobalFoodMatchReason.fingerprintExact;
    }

    final itemName = item.normalizedName;
    final isExactNameMatch =
        product.normalizedName == itemName && itemName.isNotEmpty;
    if (isExactNameMatch) {
      score += 45;
      if (reason != GlobalFoodMatchReason.fingerprintExact) {
        reason = GlobalFoodMatchReason.nameExact;
      }
    }

    final itemBrand = item.normalizedBrand;
    final productBrand = product.normalizedBrand ?? '';
    if (itemBrand.isNotEmpty && productBrand == itemBrand) {
      score += 25;
    }

    final itemCategory = item.normalizedCategory;
    final productCategory = normalizeGlobalFoodText(product.category ?? '');
    if (itemCategory.isNotEmpty && productCategory == itemCategory) {
      score += 8;
    }

    final itemStoreName = item.normalizedStoreName;
    final productStoreName = product.normalizedStoreName ?? '';
    final isStoreMatch =
        itemStoreName.isNotEmpty && productStoreName == itemStoreName;
    if (isStoreMatch) {
      score += isExactNameMatch ? 12 : 6;
    }

    final overlap = product.searchTokens
        .where(item.nameTokenSet.contains)
        .length;
    if (overlap > 0) {
      score += overlap * 6;
    }

    if (score < 12) {
      return null;
    }
    if (reason != GlobalFoodMatchReason.fingerprintExact &&
        isExactNameMatch &&
        itemBrand.isNotEmpty &&
        productBrand == itemBrand) {
      reason = GlobalFoodMatchReason.nameBrandStrong;
    }

    return GlobalFoodMatchCandidate(
      item: product,
      score: score,
      reason: reason,
    );
  }

  List<String> _queryNameTokensFor(String name) {
    final tokens = buildGlobalFoodSearchTokens(
      name: name,
    ).toSet().toList(growable: false);
    tokens.sort((left, right) {
      final lengthCompare = right.length.compareTo(left.length);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      return left.compareTo(right);
    });
    return tokens.take(_globalFoodQueryTokenLimit).toList(growable: false);
  }

  bool _hasConfidentLead(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.length < 2) {
      return true;
    }
    return candidates.first.score - candidates[1].score >= 8;
  }

  String? _queryFoodFingerprintFor(InventoryItem item) {
    final fingerprint = item.resolvedFoodFingerprint.trim();
    if (fingerprint.isEmpty || fingerprint == 'unknown_food') {
      return null;
    }
    return fingerprint;
  }
}

class _GlobalFoodMatcherQuery {
  const _GlobalFoodMatcherQuery({
    required this.normalizedName,
    required this.normalizedStoreName,
    required this.barcode,
    required this.foodFingerprint,
    required this.searchTokens,
  });

  final String? normalizedName;
  final String? normalizedStoreName;
  final String? barcode;
  final String? foodFingerprint;
  final List<String> searchTokens;
}

class _LocalMatchInput {
  const _LocalMatchInput({
    required this.normalizedName,
    required this.normalizedBrand,
    required this.normalizedCategory,
    required this.normalizedStoreName,
    required this.foodFingerprint,
    required this.nameTokens,
    required this.nameTokenSet,
    this.barcode,
  });

  final String normalizedName;
  final String normalizedBrand;
  final String normalizedCategory;
  final String normalizedStoreName;
  final String? foodFingerprint;
  final List<String> nameTokens;
  final Set<String> nameTokenSet;
  final String? barcode;
}
