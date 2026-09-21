import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_local_candidate_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_matcher_limits.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_receipt_alias_matcher.dart';
import 'package:yamt/features/inventory/application/off_product_candidate_source.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'global_food_item_matcher.g.dart';

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
  new({
    this._globalFoodItemRepository,
    GlobalFoodReceiptAliasRepository? globalFoodReceiptAliasRepository,
    OffProductSearchRepository? offProductSearchRepository,
    GlobalFoodReceiptAliasMatcher? receiptAliasMatcher,
  }) : _localCandidateMatcher = const GlobalFoodLocalCandidateMatcher(),
       _receiptAliasMatcher =
           receiptAliasMatcher ??
           GlobalFoodReceiptAliasMatcher(
             repository: globalFoodReceiptAliasRepository,
           ),
       _externalCandidateSource = OffProductCandidateSource(
         repository: offProductSearchRepository,
       );

  final GlobalFoodItemRepository? _globalFoodItemRepository;
  final GlobalFoodLocalCandidateMatcher _localCandidateMatcher;
  final GlobalFoodReceiptAliasMatcher _receiptAliasMatcher;
  final OffProductCandidateSource _externalCandidateSource;

  /// Find candidates.
  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    final localInput = _localCandidateMatcher.buildLocalMatchInput(item);
    final query = GlobalFoodLocalCandidateMatcher.buildQuery(localInput);
    final aliasMatchesFuture = _receiptAliasMatcher.findMatches(
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
        .map(candidateFromExternalResult)
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
    return (_dedupeCandidates(candidates)..sort((left, right) {
          final byScore = right.score.compareTo(left.score);
          if (byScore != 0) {
            return byScore;
          }
          if (left.requiresPersistence != right.requiresPersistence) {
            return left.requiresPersistence ? 1 : -1;
          }
          return left.item.id.compareTo(right.item.id);
        }))
        .take(globalFoodReviewCandidateLimitPerSource)
        .toList(growable: false);
  }

  List<GlobalFoodMatchCandidate> _finalizeExternalBucket(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    return candidates
        .take(globalFoodReviewCandidateLimitPerSource)
        .toList(growable: false);
  }


  Future<List<GlobalFoodMatchCandidate>> _findLocalMatches({
    required LocalMatchInput localInput,
    required GlobalFoodMatcherQuery query,
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
    );
    return _localCandidateMatcher.scoreCandidates(localInput, products);
  }
}
