import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/debug/debug_log.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_candidate_resolution_service.dart';
import 'package:yamt/features/scanner/domain/receipt_review_candidate_lookup.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_item_draft_extensions.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_item_processor.dart';

part 'receipt_review_sheet_controller.g.dart';

const _receiptReviewSheetControllerLogName = 'ReceiptReviewSheetController';
const _lazyCandidateResolutionConcurrency = 3;

/// Immutable receipt review sheet state.
@immutable
class ReceiptReviewSheetState {
  /// Creates receipt review sheet state.
  ReceiptReviewSheetState({
    required List<ReceiptReviewItemDraft> items,
    required this.metadata,
    this.isSaving = false,
    this.candidateLoadingItemId,
  }) : items = List<ReceiptReviewItemDraft>.unmodifiable(items);

  /// Review drafts currently shown by the sheet.
  final List<ReceiptReviewItemDraft> items;

  /// Receipt metadata derived from review drafts.
  final ReceiptReviewMetadata metadata;

  /// Whether save is in progress.
  final bool isSaving;

  /// Item id with candidate lookup loading indicator.
  final String? candidateLoadingItemId;

  /// Whether all savable items can be persisted.
  bool get canSave {
    if (isSaving) {
      return false;
    }
    final savableItems = items.where((item) => item.canBeSavedToInventory);
    if (savableItems.isEmpty) {
      return false;
    }
    return savableItems.every((item) => item.isConfirmed);
  }

  /// Copy with.
  ReceiptReviewSheetState copyWith({
    List<ReceiptReviewItemDraft>? items,
    ReceiptReviewMetadata? metadata,
    bool? isSaving,
    Object? candidateLoadingItemId = _keepValue,
  }) {
    return ReceiptReviewSheetState(
      items: items ?? this.items,
      metadata: metadata ?? this.metadata,
      isSaving: isSaving ?? this.isSaving,
      candidateLoadingItemId: candidateLoadingItemId == _keepValue
          ? this.candidateLoadingItemId
          : candidateLoadingItemId as String?,
    );
  }
}

/// Controls receipt review sheet state and candidate resolution.
@Riverpod()
class ReceiptReviewSheetController extends _$ReceiptReviewSheetController {
  static const _itemProcessor = ReceiptReviewItemProcessor();

  final _candidateResolutionFutures =
      <String, Future<ReceiptReviewItemDraft?>>{};
  final _candidateResolvedItemIds = <String>{};

  @override
  ReceiptReviewSheetState build(List<ReceiptReviewItemDraft> initialItems) {
    _candidateResolutionFutures.clear();
    _candidateResolvedItemIds.clear();
    final result = _itemProcessor.process(initialItems);
    final preparedItems = <ReceiptReviewItemDraft>[
      for (final draft in result.items)
        draft.syncToSelectedCandidate().prepareForReceiptReview(),
    ];

    ref.onDispose(() {
      for (final future in _candidateResolutionFutures.values) {
        future.ignore();
      }
      _candidateResolutionFutures.clear();
      _candidateResolvedItemIds.clear();
    });

    return ReceiptReviewSheetState(
      items: preparedItems,
      metadata: result.metadata,
    );
  }

  /// Resolve pending candidates in bounded batches.
  Future<void> resolveCandidatesLazily() async {
    final itemIds = _pendingCandidateItemIds();
    for (var index = 0; ref.mounted && index < itemIds.length;) {
      final nextIndex = index + _lazyCandidateResolutionConcurrency;
      final endIndex = nextIndex < itemIds.length ? nextIndex : itemIds.length;
      final batchItemIds = itemIds.sublist(index, endIndex);
      index = endIndex;
      await Future.wait(<Future<ReceiptReviewItemDraft?>>[
        for (final itemId in batchItemIds) _resolveCandidatesForItem(itemId),
      ]);
    }
  }

  /// Prepare draft for picker, resolving candidates if needed.
  Future<ReceiptReviewItemDraft?> prepareDraftForCandidateSelection(
    String itemId,
  ) async {
    final draft = draftForItemId(itemId);
    if (draft == null || !draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.hasCandidates || _candidateResolvedItemIds.contains(itemId)) {
      return draft;
    }

    return _resolveCandidatesForItem(itemId, showLoading: true);
  }

  /// Draft for item id.
  ReceiptReviewItemDraft? draftForItemId(String itemId) {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return null;
    }
    return state.items[index];
  }

  /// Replace item from editor result.
  void applyEditedItem(String itemId, InventoryItem editedItem) {
    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(item: editedItem).prepareForReceiptReview();
    });
  }

  /// Select candidate.
  void selectCandidate(String itemId, String candidateId) {
    _replaceDraftByItemId(itemId, (draft) {
      return draft
          .selectCandidate(candidateId)
          .syncToSelectedCandidate()
          .prepareForReceiptReview();
    });
  }

  /// Apply manual product result.
  void applyManualProductResult({
    required String itemId,
    required InventoryItem item,
    required OffProductSearchResult? selectedProduct,
    required String? selectedGlobalFoodItemId,
  }) {
    final resolver = ref.read(receiptReviewCandidateResolutionServiceProvider);
    _replaceDraftByItemId(itemId, (draft) {
      return resolver.applyManualProductResult(
        draft: draft,
        item: item,
        selectedProduct: selectedProduct,
        selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      );
    });
  }

  /// Toggle item confirmation. Returns item id to scroll to if confirmed.
  String? toggleItemConfirmed(String itemId) {
    if (state.isSaving) {
      return null;
    }
    final draft = draftForItemId(itemId);
    if (draft == null || !draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.isConfirmed) {
      _replaceDraftByItemId(itemId, (currentDraft) {
        return currentDraft.copyWith(isConfirmed: false);
      });
      return null;
    }
    if (!draft.canConfirmReceiptReview) {
      return null;
    }

    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(
        isConfirmed: true,
        selectionNeedsReview: false,
        weightNeedsAttention: false,
      );
    });
    return nextPendingItemId(afterItemId: itemId);
  }

  /// Next unconfirmed savable item after the current item.
  String? nextPendingItemId({required String afterItemId}) {
    final currentIndex = _indexForItemId(afterItemId);
    if (currentIndex < 0) {
      return null;
    }

    for (var index = currentIndex + 1; index < state.items.length; index++) {
      final draft = state.items[index];
      if (draft.canBeSavedToInventory && !draft.isConfirmed) {
        return draft.item.id;
      }
    }
    for (final draft in state.items) {
      if (draft.canBeSavedToInventory && !draft.isConfirmed) {
        return draft.item.id;
      }
    }
    return null;
  }

  /// Save reviewed drafts.
  Future<void> saveReviewedItems(
    Future<void> Function(List<ReceiptReviewItemDraft> items) onSaveTap,
  ) async {
    if (!state.canSave) {
      return;
    }

    state = state.copyWith(isSaving: true);
    try {
      await onSaveTap(List<ReceiptReviewItemDraft>.from(state.items));
    } on Object catch (error, stackTrace) {
      appLog(
        'Receipt review save failed',
        name: _receiptReviewSheetControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  List<String> _pendingCandidateItemIds() {
    return <String>[
      for (final draft in state.items)
        if (_needsCandidateResolution(draft)) draft.item.id,
    ];
  }

  bool _needsCandidateResolution(ReceiptReviewItemDraft draft) {
    final itemId = draft.item.id;
    return draft.canBeSavedToInventory &&
        !draft.hasCandidates &&
        !_candidateResolvedItemIds.contains(itemId) &&
        !_candidateResolutionFutures.containsKey(itemId);
  }

  Future<ReceiptReviewItemDraft?> _resolveCandidatesForItem(
    String itemId, {
    bool showLoading = false,
  }) {
    final pendingFuture = _candidateResolutionFutures[itemId];
    if (pendingFuture != null) {
      if (showLoading) {
        _setCandidateLoadingItemId(itemId);
      }
      return pendingFuture.whenComplete(() {
        if (!ref.mounted) {
          return;
        }
        if (showLoading) {
          _clearCandidateLoadingItemId(itemId);
        }
      });
    }

    final resolver = ref.read(receiptReviewCandidateResolutionServiceProvider);
    final future = _runCandidateResolution(itemId, resolver: resolver);
    _candidateResolutionFutures[itemId] = future;
    if (showLoading) {
      _setCandidateLoadingItemId(itemId);
    }

    return future.whenComplete(() {
      if (!ref.mounted) {
        return;
      }
      if (identical(_candidateResolutionFutures[itemId], future)) {
        _candidateResolutionFutures.remove(itemId)?.ignore();
      }
      if (showLoading) {
        _clearCandidateLoadingItemId(itemId);
      }
    });
  }

  Future<ReceiptReviewItemDraft?> _runCandidateResolution(
    String itemId, {
    required ReceiptReviewCandidateResolutionService resolver,
  }) async {
    final draft = draftForItemId(itemId);
    if (draft == null || !draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.hasCandidates || _candidateResolvedItemIds.contains(itemId)) {
      return draft;
    }

    final lookupItem = draft.item;
    final resolvedDraft = await resolver.resolveDraftCandidates(draft);
    if (!ref.mounted) {
      return null;
    }
    final currentIndex = _indexForItemId(itemId);
    if (currentIndex < 0) {
      return null;
    }

    final currentDraft = state.items[currentIndex];
    if (!hasSameReceiptReviewCandidateLookupInput(
      lookupItem,
      currentDraft.item,
    )) {
      return currentDraft;
    }
    final nextDraft = currentDraft == draft
        ? resolvedDraft
        : mergeResolvedReceiptReviewCandidates(
            currentDraft: currentDraft,
            resolvedDraft: resolvedDraft,
            lookupItem: lookupItem,
          );
    _candidateResolvedItemIds.add(itemId);
    _replaceItemAt(currentIndex, nextDraft);
    return nextDraft;
  }

  void _setCandidateLoadingItemId(String itemId) {
    if (state.candidateLoadingItemId == itemId) {
      return;
    }
    state = state.copyWith(candidateLoadingItemId: itemId);
  }

  void _clearCandidateLoadingItemId(String itemId) {
    if (state.candidateLoadingItemId != itemId) {
      return;
    }
    state = state.copyWith(candidateLoadingItemId: null);
  }

  int _indexForItemId(String itemId) {
    return state.items.indexWhere((draft) => draft.item.id == itemId);
  }

  void _replaceDraftByItemId(
    String itemId,
    ReceiptReviewItemDraft Function(ReceiptReviewItemDraft draft) transform,
  ) {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return;
    }
    final currentDraft = state.items[index];
    final nextDraft = transform(currentDraft);
    final shouldInvalidateCandidateResolution =
        !hasSameReceiptReviewCandidateLookupInput(
          currentDraft.item,
          nextDraft.item,
        );
    if (shouldInvalidateCandidateResolution) {
      _candidateResolvedItemIds.remove(itemId);
      _candidateResolutionFutures.remove(itemId)?.ignore();
      if (state.candidateLoadingItemId == itemId) {
        state = state.copyWith(candidateLoadingItemId: null);
      }
    }
    _replaceItemAt(index, nextDraft);
  }

  void _replaceItemAt(int index, ReceiptReviewItemDraft draft) {
    final items = <ReceiptReviewItemDraft>[
      for (final entry in state.items.indexed)
        if (entry.$1 == index) draft else entry.$2,
    ];
    state = state.copyWith(items: items);
  }
}

const Object _keepValue = Object();
