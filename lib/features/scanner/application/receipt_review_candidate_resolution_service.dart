import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_item_draft_extensions.dart';

part 'receipt_review_candidate_resolution_service.g.dart';

const _candidateResolutionLogName = 'ReceiptReviewCandidateResolutionService';

/// Receipt review candidate resolution service.
@Riverpod()
ReceiptReviewCandidateResolutionService receiptReviewCandidateResolutionService(
  Ref ref,
) {
  return ReceiptReviewCandidateResolutionService(
    matcher: ref.watch(globalFoodItemMatcherProvider),
  );
}

/// Resolves and applies global food candidates for receipt review drafts.
class ReceiptReviewCandidateResolutionService {
  /// Creates a candidate resolution service.
  const ReceiptReviewCandidateResolutionService({
    required GlobalFoodItemMatcher matcher,
  }) : _matcher = matcher;

  final GlobalFoodItemMatcher _matcher;

  /// Resolves candidates and applies the default automatic selection.
  Future<ReceiptReviewItemDraft> resolveDraftCandidates(
    ReceiptReviewItemDraft draft,
  ) async {
    if (!draft.canBeSavedToInventory || draft.hasCandidates) {
      return draft;
    }

    final stopwatch = Stopwatch()..start();
    final candidates = await _findCandidates(draft);
    stopwatch.stop();
    _debugLogCandidateResolutionTiming(
      draft: draft,
      candidateCount: candidates.length,
      elapsed: stopwatch.elapsed,
    );
    return _applyCandidateResolution(draft, candidates);
  }

  /// Applies a manual product result from the product-search flow.
  ReceiptReviewItemDraft applyManualProductResult({
    required ReceiptReviewItemDraft draft,
    required InventoryItem item,
    required OffProductSearchResult? selectedProduct,
    required String? selectedGlobalFoodItemId,
  }) {
    if (selectedProduct == null && selectedGlobalFoodItemId == null) {
      return draft
          .copyWith(item: item)
          .selectNewItem()
          .prepareForReceiptReview();
    }

    final scannedCandidate = selectedProduct != null
        ? _matcher.candidateFromExternalResult(selectedProduct)
        : item.toRecentReceiptReviewCandidate(
            globalFoodItemId: selectedGlobalFoodItemId!,
          );
    final mergedCandidates = <GlobalFoodMatchCandidate>[
      scannedCandidate,
      ...draft.candidates.where(
        (candidate) => candidate.item.id != scannedCandidate.item.id,
      ),
    ];
    final updatedDraft = draft
        .copyWith(
          item: item,
          candidates: mergedCandidates,
          selectionNeedsReview: false,
        )
        .selectCandidate(scannedCandidate.item.id);
    return updatedDraft.prepareForReceiptReview();
  }

  Future<List<GlobalFoodMatchCandidate>> _findCandidates(
    ReceiptReviewItemDraft draft,
  ) async {
    try {
      return await _matcher.findCandidates(draft.item);
    } catch (error, stackTrace) {
      log(
        'Receipt review candidate lookup failed',
        name: _candidateResolutionLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalFoodMatchCandidate>[];
    }
  }

  ReceiptReviewItemDraft _applyCandidateResolution(
    ReceiptReviewItemDraft draft,
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    return draft
        .copyWith(candidates: candidates)
        .applyAutomaticSelection(
          _matcher.defaultSelectionFor(candidates),
          selectionNeedsReview: _matcher.defaultSelectionNeedsReviewFor(
            candidates,
          ),
        )
        .syncToSelectedCandidate()
        .prepareForReceiptReview();
  }
}

void _debugLogCandidateResolutionTiming({
  required ReceiptReviewItemDraft draft,
  required int candidateCount,
  required Duration elapsed,
}) {
  assert(() {
    log(
      'Resolved ${draft.item.id} to $candidateCount candidate(s) in '
      '${elapsed.inMilliseconds}ms.',
      name: _candidateResolutionLogName,
    );
    return true;
  }(), 'Receipt candidate timing log should run only in debug mode.');
}
