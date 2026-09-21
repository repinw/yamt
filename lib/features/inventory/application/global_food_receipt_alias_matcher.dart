import 'package:yamt/features/inventory/application/'
    'global_food_local_candidate_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_matcher_limits.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Matches learned receipt aliases against an inventory item.
class GlobalFoodReceiptAliasMatcher {
  /// Creates a receipt alias matcher.
  const new({
    required this.repository,
    this.localCandidateMatcher = const GlobalFoodLocalCandidateMatcher(),
  });

  /// Receipt alias repository for searching learned alias mappings.
  final GlobalFoodReceiptAliasRepository? repository;

  /// Local candidate matcher for scoring candidates.
  final GlobalFoodLocalCandidateMatcher localCandidateMatcher;

  /// Finds alias candidate matches for [item] using normalized [localInput].
  Future<List<GlobalFoodMatchCandidate>> findMatches({
    required InventoryItem item,
    required LocalMatchInput localInput,
  }) async {
    final aliasRepository = repository;
    if (aliasRepository == null) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final normalizedStoreName = normalizeGlobalFoodReceiptAliasStoreName(
      item.storeName,
    );
    final normalizedReceiptName = normalizeGlobalFoodReceiptObservedName(
      item.ocrName ?? item.name,
    );
    if (normalizedStoreName == null || normalizedReceiptName == null) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final aliases = await aliasRepository.searchCandidates(
      normalizedStoreName: normalizedStoreName,
      normalizedReceiptName: normalizedReceiptName,
      limit: globalFoodCandidateQueryLimit,
    );
    return _buildAliasMatches(
      localInput: localInput,
      aliases: aliases,
      normalizedReceiptName: normalizedReceiptName,
      compactReceiptName: compactGlobalFoodReceiptAliasText(
        normalizedReceiptName,
      ),
      receiptSearchTokens: buildGlobalFoodReceiptAliasSearchTokens(
        normalizedReceiptName,
      ).toSet(),
    );
  }

  List<GlobalFoodMatchCandidate> _buildAliasMatches({
    required LocalMatchInput localInput,
    required List<GlobalFoodReceiptAlias> aliases,
    required String normalizedReceiptName,
    required String compactReceiptName,
    required Set<String> receiptSearchTokens,
  }) {
    final products = aliases
        .map((alias) => alias.globalFoodItem)
        .toList(growable: false);
    final scoredMatches = localCandidateMatcher.scoreCandidates(
      localInput,
      products,
    );
    final scoredById = <String, GlobalFoodMatchCandidate>{
      for (final candidate in scoredMatches) candidate.item.id: candidate,
    };
    return aliases
        .map((alias) {
          final product = alias.globalFoodItem;
          final genericScore = scoredById[product.id]?.score ?? 0;
          final aliasNameScore = _scoreAliasReceiptName(
            alias: alias,
            normalizedReceiptName: normalizedReceiptName,
            compactReceiptName: compactReceiptName,
            receiptSearchTokens: receiptSearchTokens,
          );
          if (aliasNameScore < 12) {
            return null;
          }
          return GlobalFoodMatchCandidate(
            item: product,
            score:
                120 +
                genericScore +
                alias.selectionCount.toDouble() +
                aliasNameScore,
            reason: GlobalFoodMatchReason.receiptAliasExact,
          );
        })
        .whereType<GlobalFoodMatchCandidate>()
        .toList(growable: false);
  }

  double _scoreAliasReceiptName({
    required GlobalFoodReceiptAlias alias,
    required String normalizedReceiptName,
    required String compactReceiptName,
    required Set<String> receiptSearchTokens,
  }) {
    var score = 0.0;
    if (alias.normalizedReceiptName == normalizedReceiptName) {
      score += 24;
    }
    if (alias.compactReceiptName == compactReceiptName &&
        compactReceiptName.isNotEmpty) {
      score += 16;
    }

    final meaningfulReceiptTokens = receiptSearchTokens
        .where(
          (token) =>
              token.length >= 3 &&
              !RegExp(r'^\d+$').hasMatch(token) &&
              !isReceiptAliasNoise(token),
        )
        .toSet();
    final overlap = alias.receiptSearchTokens
        .where(
          (token) =>
              token.length >= 3 &&
              !RegExp(r'^\d+$').hasMatch(token) &&
              !isReceiptAliasNoise(token) &&
              meaningfulReceiptTokens.contains(token),
        )
        .length;
    if (overlap > 0) {
      score += overlap * 6;
    }

    if (compactReceiptName.length >= 4 &&
        alias.compactReceiptName.length >= 4 &&
        (alias.compactReceiptName.contains(compactReceiptName) ||
            compactReceiptName.contains(alias.compactReceiptName))) {
      score += 8;
    }
    return score;
  }
}
