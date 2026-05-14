import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

const int _globalFoodQueryTokenLimit = 10;

/// Scores local global-food products against an inventory item.
class GlobalFoodLocalCandidateMatcher {
  /// Creates a local candidate matcher.
  const GlobalFoodLocalCandidateMatcher();

  /// Builds normalized local matching input for [item].
  LocalMatchInput buildLocalMatchInput(InventoryItem item) {
    final normalizedName = normalizeGlobalFoodText(item.name);
    final normalizedBrand = normalizeGlobalFoodText(item.brand ?? '');
    final normalizedCategory = normalizeGlobalFoodText(item.category ?? '');
    final normalizedStoreName = normalizeGlobalFoodText(
      normalizeStoreName(item.storeName) ?? '',
    );
    final foodFingerprint = _queryFoodFingerprintFor(item);
    final tokens = _queryNameTokensFor(item.name);
    return LocalMatchInput(
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

  /// Builds repository query params from normalized [localMatchInput].
  static GlobalFoodMatcherQuery? buildQuery(LocalMatchInput localMatchInput) {
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

    return GlobalFoodMatcherQuery(
      normalizedName: normalizedName.isEmpty ? null : normalizedName,
      normalizedStoreName: localMatchInput.normalizedStoreName.isEmpty
          ? null
          : localMatchInput.normalizedStoreName,
      barcode: barcode,
      foodFingerprint: foodFingerprint,
      searchTokens: searchTokens,
    );
  }

  /// Scores [products] against normalized [item] input.
  List<GlobalFoodMatchCandidate> scoreCandidates(
    LocalMatchInput item,
    Iterable<GlobalFoodItem> products,
  ) {
    return products
        .map((product) => _scoreCandidate(item, product))
        .whereType<GlobalFoodMatchCandidate>()
        .toList(growable: false)
      ..sort((left, right) => right.score.compareTo(left.score));
  }

  /// Returns the confident default candidate id, if one exists.
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

  /// Whether candidate selection needs explicit user review.
  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return false;
    }
    return defaultSelectionFor(candidates) == null;
  }

  GlobalFoodMatchCandidate? _scoreCandidate(
    LocalMatchInput item,
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
    return (buildGlobalFoodSearchTokens(
          name: name,
        ).toSet().toList(growable: false)..sort((left, right) {
          final lengthCompare = right.length.compareTo(left.length);
          if (lengthCompare != 0) {
            return lengthCompare;
          }
          return left.compareTo(right);
        }))
        .take(_globalFoodQueryTokenLimit)
        .toList(growable: false);
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

/// Query fields passed to the global food repository.
class GlobalFoodMatcherQuery {
  /// Creates global food matcher query fields.
  const GlobalFoodMatcherQuery({
    required this.normalizedName,
    required this.normalizedStoreName,
    required this.barcode,
    required this.foodFingerprint,
    required this.searchTokens,
  });

  /// Normalized product name when available.
  final String? normalizedName;

  /// Normalized store name when available.
  final String? normalizedStoreName;

  /// Normalized barcode when available.
  final String? barcode;

  /// Resolved food fingerprint when available.
  final String? foodFingerprint;

  /// Search tokens for fuzzy name matching.
  final List<String> searchTokens;
}

/// Normalized inventory item fields used for local candidate matching.
class LocalMatchInput {
  /// Creates normalized local match input.
  const LocalMatchInput({
    required this.normalizedName,
    required this.normalizedBrand,
    required this.normalizedCategory,
    required this.normalizedStoreName,
    required this.foodFingerprint,
    required this.nameTokens,
    required this.nameTokenSet,
    this.barcode,
  });

  /// Normalized product name.
  final String normalizedName;

  /// Normalized brand.
  final String normalizedBrand;

  /// Normalized category.
  final String normalizedCategory;

  /// Normalized store name.
  final String normalizedStoreName;

  /// Resolved food fingerprint when useful for matching.
  final String? foodFingerprint;

  /// Ordered name tokens.
  final List<String> nameTokens;

  /// Name token lookup set.
  final Set<String> nameTokenSet;

  /// Normalized barcode when available.
  final String? barcode;
}
