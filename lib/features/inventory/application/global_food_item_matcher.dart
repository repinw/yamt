import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'global_food_item_matcher.g.dart';
part 'global_food_local_candidate_matcher.dart';
part 'off_product_candidate_source.dart';

const int _globalFoodCandidateQueryLimit = 20;
const int _globalFoodReviewCandidateLimitPerSource = 5;

/// Global food item matcher.
@riverpod
GlobalFoodItemMatcher globalFoodItemMatcher(Ref ref) {
  return GlobalFoodItemMatcher(
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    globalFoodReceiptAliasRepository: ref.watch(
      globalFoodReceiptAliasRepositoryProvider,
    ),
    offProductSearchRepository: ref.watch(offProductSearchRepositoryProvider),
  );
}

/// Defines global food item matcher.
class GlobalFoodItemMatcher {
  /// Creates an instance.
  GlobalFoodItemMatcher({
    GlobalFoodItemRepository? globalFoodItemRepository,
    GlobalFoodReceiptAliasRepository? globalFoodReceiptAliasRepository,
    OffProductSearchRepository? offProductSearchRepository,
  }) : _globalFoodItemRepository = globalFoodItemRepository,
       _globalFoodReceiptAliasRepository = globalFoodReceiptAliasRepository,
       _localCandidateMatcher = const _GlobalFoodLocalCandidateMatcher(),
       _externalCandidateSource = _OffProductCandidateSource(
         repository: offProductSearchRepository,
       );

  final GlobalFoodItemRepository? _globalFoodItemRepository;
  final GlobalFoodReceiptAliasRepository? _globalFoodReceiptAliasRepository;
  final _GlobalFoodLocalCandidateMatcher _localCandidateMatcher;
  final _OffProductCandidateSource _externalCandidateSource;

  /// Find candidates.
  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    final localInput = _localCandidateMatcher.buildLocalMatchInput(item);
    final query = _GlobalFoodLocalCandidateMatcher.buildQuery(localInput);
    final aliasMatchesFuture = _findAliasMatches(
      item: item,
      localInput: localInput,
    );
    final localMatchesFuture = query == null
        ? Future<List<GlobalFoodMatchCandidate>>.value(
            const <GlobalFoodMatchCandidate>[],
          )
        : _findLocalMatches(localInput: localInput, query: query);
    final externalResultsFuture = _externalCandidateSource.search(item);

    final aliasMatches = await aliasMatchesFuture;
    final localMatches = await localMatchesFuture;
    final externalResults = await externalResultsFuture;
    return _finalizeCandidates(
      localCandidates: <GlobalFoodMatchCandidate>[
        ...aliasMatches,
        ...localMatches,
      ],
      externalCandidates: _buildExternalMatches(
        externalResults: externalResults,
      ),
    );
  }

  /// Find candidates by item id.
  Future<Map<String, List<GlobalFoodMatchCandidate>>> findCandidatesByItemId(
    Iterable<InventoryItem> items,
  ) async {
    final entries = await Future.wait(
      items.map((item) async {
        return MapEntry<String, List<GlobalFoodMatchCandidate>>(
          item.id,
          await findCandidates(item),
        );
      }),
    );
    return Map<String, List<GlobalFoodMatchCandidate>>.fromEntries(entries);
  }

  /// Default selection for.
  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first.item.id;
  }

  /// Default selection needs review for.
  bool defaultSelectionNeedsReviewFor(List<GlobalFoodMatchCandidate> _) {
    return false;
  }

  /// Candidate from external result.
  GlobalFoodMatchCandidate candidateFromExternalResult(
    OffProductSearchResult result,
  ) {
    final product = _externalCandidateSource.productFrom(result);
    return GlobalFoodMatchCandidate(
      item: product,
      score: result.score,
      reason: GlobalFoodMatchReason.externalSearch,
      requiresPersistence: true,
    );
  }

  List<GlobalFoodMatchCandidate> _buildExternalMatches({
    required List<OffProductSearchResult> externalResults,
  }) {
    return externalResults
        .map((result) {
          return candidateFromExternalResult(result);
        })
        .toList(growable: false);
  }

  List<GlobalFoodMatchCandidate> _finalizeCandidates({
    required List<GlobalFoodMatchCandidate> localCandidates,
    required List<GlobalFoodMatchCandidate> externalCandidates,
  }) {
    final finalizedLocal = _finalizeSourceBucket(localCandidates);
    final finalizedExternal = _finalizeExternalBucket(externalCandidates);
    return <GlobalFoodMatchCandidate>[...finalizedLocal, ...finalizedExternal];
  }

  List<GlobalFoodMatchCandidate> _dedupeCandidates(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    final bestByKey = <String, GlobalFoodMatchCandidate>{};
    for (final candidate in candidates) {
      final key = _candidateKey(candidate);
      final existing = bestByKey[key];
      final shouldReplace =
          existing == null ||
          candidate.score > existing.score ||
          (candidate.score == existing.score &&
              !candidate.requiresPersistence &&
              existing.requiresPersistence);
      if (shouldReplace) {
        bestByKey[key] = candidate;
      }
    }
    return bestByKey.values.toList(growable: false);
  }

  String _candidateKey(GlobalFoodMatchCandidate candidate) {
    final barcode = candidate.item.normalizedBarcode;
    if (barcode != null && barcode.isNotEmpty) {
      return 'barcode:$barcode';
    }

    return 'name:${candidate.item.normalizedName}'
        '|brand:${candidate.item.normalizedBrand ?? ''}';
  }

  List<GlobalFoodMatchCandidate> _finalizeSourceBucket(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    final deduped = _dedupeCandidates(candidates);
    deduped.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      if (byScore != 0) {
        return byScore;
      }
      if (left.requiresPersistence != right.requiresPersistence) {
        return left.requiresPersistence ? 1 : -1;
      }
      return left.item.id.compareTo(right.item.id);
    });
    return deduped
        .take(_globalFoodReviewCandidateLimitPerSource)
        .toList(growable: false);
  }

  List<GlobalFoodMatchCandidate> _finalizeExternalBucket(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    return candidates
        .take(_globalFoodReviewCandidateLimitPerSource)
        .toList(growable: false);
  }

  Future<List<GlobalFoodMatchCandidate>> _findAliasMatches({
    required InventoryItem item,
    required _LocalMatchInput localInput,
  }) async {
    final repository = _globalFoodReceiptAliasRepository;
    if (repository == null) {
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

    final aliases = await repository.searchCandidates(
      normalizedStoreName: normalizedStoreName,
      normalizedReceiptName: normalizedReceiptName,
      limit: _globalFoodCandidateQueryLimit,
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
    required _LocalMatchInput localInput,
    required List<GlobalFoodReceiptAlias> aliases,
    required String normalizedReceiptName,
    required String compactReceiptName,
    required Set<String> receiptSearchTokens,
  }) {
    final products = aliases
        .map((alias) => alias.globalFoodItem)
        .toList(growable: false);
    final scoredMatches = _localCandidateMatcher.scoreCandidates(
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
          if (aliasNameScore <= 0) {
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

    final overlap = alias.receiptSearchTokens
        .where(receiptSearchTokens.contains)
        .length;
    if (overlap > 0) {
      score += overlap * 6;
    }

    if (compactReceiptName.length >= 4 &&
        alias.compactReceiptName.isNotEmpty &&
        (alias.compactReceiptName.contains(compactReceiptName) ||
            compactReceiptName.contains(alias.compactReceiptName))) {
      score += 8;
    }
    return score;
  }

  Future<List<GlobalFoodMatchCandidate>> _findLocalMatches({
    required _LocalMatchInput localInput,
    required _GlobalFoodMatcherQuery query,
  }) async {
    final repository = _globalFoodItemRepository;
    if (repository == null) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final products = await repository.searchCandidates(
      normalizedName: query.normalizedName,
      normalizedStoreName: query.normalizedStoreName,
      barcode: query.barcode,
      foodFingerprint: query.foodFingerprint,
      searchTokens: query.searchTokens,
      limit: _globalFoodCandidateQueryLimit,
    );
    return _localCandidateMatcher.scoreCandidates(localInput, products);
  }
}
