import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'global_food_item_matcher.g.dart';
part 'global_food_local_candidate_matcher.dart';
part 'off_product_candidate_source.dart';

const int _globalFoodCandidateQueryLimit = 20;
const int _globalFoodReviewCandidateLimit = 5;

@Riverpod(keepAlive: true)
GlobalFoodItemMatcher globalFoodItemMatcher(Ref ref) {
  return GlobalFoodItemMatcher(
    offProductSearchRepository: ref.watch(offProductSearchRepositoryProvider),
  );
}

class GlobalFoodItemMatcher {
  GlobalFoodItemMatcher({
    GlobalFoodItemRepository? repository,
    InventoryItemRepository? inventoryRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
    OffProductSearchRepository? offProductSearchRepository,
  }) : _localCandidateMatcher = const _GlobalFoodLocalCandidateMatcher(),
       _externalCandidateSource = _OffProductCandidateSource(
         repository: offProductSearchRepository,
       );

  final _GlobalFoodLocalCandidateMatcher _localCandidateMatcher;
  final _OffProductCandidateSource _externalCandidateSource;

  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    if (!_canSearch(item)) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final externalResults = await _externalCandidateSource.search(item);
    return _finalizeCandidates(
      _buildExternalMatches(externalResults: externalResults),
    );
  }

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

  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first.item.id;
  }

  bool defaultSelectionNeedsReviewFor(List<GlobalFoodMatchCandidate> _) {
    return false;
  }

  GlobalFoodMatchCandidate candidateFromExternalResult(
    OffProductSearchResult result,
  ) {
    final product = _externalCandidateSource.productFrom(result);
    return GlobalFoodMatchCandidate(
      item: product,
      score: _scoreExternalCandidate(result.score),
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

  bool _canSearch(InventoryItem item) {
    final localInput = _localCandidateMatcher.buildLocalMatchInput(item);
    final query = _GlobalFoodLocalCandidateMatcher.buildQuery(localInput);
    return query != null && item.name.trim().isNotEmpty;
  }

  List<GlobalFoodMatchCandidate> _finalizeCandidates(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    return _dedupeCandidates(
      candidates,
    ).take(_globalFoodReviewCandidateLimit).toList(growable: false);
  }

  double _scoreExternalCandidate(double rawScore) {
    return (60 + (rawScore / 2)).clamp(60, 89).toDouble();
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
}
