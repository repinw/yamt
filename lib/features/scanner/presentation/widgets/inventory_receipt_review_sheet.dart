import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/debug/debug_log.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_candidate_resolution_service.dart';
import 'package:yamt/features/scanner/domain/receipt_review_candidate_lookup.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft_extensions.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_item_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_preview_button.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_preview_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_header.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_item_card.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_metadata_overview.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_price_overview.dart';
import 'package:yamt/l10n/app_localizations.dart';

const String _receiptReviewSheetLogName = 'InventoryReceiptReviewSheet';

/// Main receipt review content shown inside the full-screen review flow.
@Dependencies([
  inventoryItemRepository,
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
class InventoryReceiptReviewSheet extends ConsumerStatefulWidget {
  /// The inventory receipt review sheet.
  const InventoryReceiptReviewSheet({
    required this.items,
    required this.onCancelTap,
    required this.onSaveTap,
    super.key,
    this.receiptPreviewBytes,
  });

  /// The items.
  final List<ReceiptReviewItemDraft> items;

  /// The on cancel tap.
  final VoidCallback onCancelTap;

  /// The on save tap.
  final Future<void> Function(List<ReceiptReviewItemDraft> items) onSaveTap;

  /// The receipt preview bytes.
  final Uint8List? receiptPreviewBytes;

  @override
  ConsumerState<InventoryReceiptReviewSheet> createState() =>
      _InventoryReceiptReviewSheetState();
}

class _InventoryReceiptReviewSheetState
    extends ConsumerState<InventoryReceiptReviewSheet> {
  static const _priceSummaryCalculator = ReceiptReviewPriceSummaryCalculator();
  static const _itemProcessor = ReceiptReviewItemProcessor();
  static const _lazyCandidateResolutionConcurrency = 3;

  late final List<ReceiptReviewItemDraft> _items;
  late final ReceiptReviewMetadata _receiptMetadata;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  final _candidateResolutionFutures =
      <String, Future<ReceiptReviewItemDraft?>>{};
  final Set<String> _candidateResolvedItemIds = <String>{};
  var _isSaving = false;
  String? _candidateLoadingItemId;

  @override
  void initState() {
    super.initState();
    final result = _itemProcessor.process(widget.items);
    _items = [
      for (final draft in result.items)
        draft.syncToSelectedCandidate().prepareForReceiptReview(),
    ];
    _receiptMetadata = result.metadata;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_resolveCandidatesLazily());
    });
  }

  bool get _canSave {
    if (_isSaving) {
      return false;
    }
    final savableItems = _items.where((item) => item.canBeSavedToInventory);
    if (savableItems.isEmpty) {
      return false;
    }
    return savableItems.every((item) => item.isConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = _currencyFormat(context);
    final priceSummary = _priceSummaryCalculator.calculate(_items);
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Material(
        color: colors.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InventoryReceiptReviewHeader(
                    isSaving: _isSaving,
                    canSave: _canSave,
                    onSaveTap: _saveReviewedItems,
                  ),
                  const SizedBox(height: 16),
                  InventoryReceiptPreviewButton(onTap: _openReceiptPreview),
                ],
              ),
            ),
            Container(height: 1, color: colors.outlineVariant),
            Expanded(
              child: _buildContent(
                context: context,
                l10n: l10n,
                currency: currency,
                priceSummary: priceSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required NumberFormat currency,
    required ReceiptReviewPriceSummary priceSummary,
  }) {
    final colors = Theme.of(context).colorScheme;

    if (_items.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.inventoryReceiptReviewEmpty),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              InventoryReceiptReviewMetadataOverview(
                storeName: _receiptMetadata.storeName,
                receiptDate: _receiptMetadata.receiptDate,
                receiptTimeText: _receiptMetadata.receiptTimeText,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.inventoryReceiptReviewDetectedItems.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildReviewItemCard(
                  context: context,
                  index: index,
                  currency: currency,
                );
              },
              childCount: _items.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              InventoryReceiptReviewPriceOverview(
                totalPrice: priceSummary.totalPrice,
                storablePrice: priceSummary.storablePrice,
                excludedPrice: priceSummary.excludedPrice,
                currency: currency,
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItemCard({
    required BuildContext context,
    required int index,
    required NumberFormat currency,
  }) {
    final draft = _items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InventoryReceiptReviewItemCard(
        key: _itemKeyFor(draft.item.id),
        draft: draft,
        index: index,
        currency: currency,
        onEditTap: _openItemEditor,
        onSwitchTap: _openCandidatePicker,
        onConfirmTap: () => _toggleItemConfirmed(draft.item.id),
        canConfirm: draft.canConfirmReceiptReview,
        isActionLoading: _candidateLoadingItemId == draft.item.id,
        isEnabled: !_isSaving,
      ),
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    if (_isSaving) {
      return;
    }
    final draft = _draftForItemId(itemId);
    if (draft == null || draft.item.isDiscount) {
      return;
    }

    final editedItem = await _showItemEditor(draft.item);
    if (!mounted || _isSaving || editedItem == null) {
      return;
    }

    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(item: editedItem).prepareForReceiptReview();
    });
  }

  Future<void> _openCandidatePicker(String itemId) async {
    if (_isSaving || _candidateLoadingItemId != null) {
      return;
    }

    final draft = await _prepareDraftForCandidateSelection(itemId);
    if (!mounted ||
        _isSaving ||
        draft == null ||
        !draft.canBeSavedToInventory) {
      return;
    }

    final selection =
        await showModalBottomSheet<ReceiptCandidatePickerSelection>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return InventoryReceiptCandidatePickerSheet(draft: draft);
          },
        );
    if (!mounted || _isSaving || selection == null) {
      return;
    }

    switch (selection.kind) {
      case ReceiptCandidatePickerSelectionKind.candidate:
        final candidateId = selection.candidateId;
        if (candidateId == null) {
          return;
        }
        _replaceDraftByItemId(itemId, (draft) {
          return draft
              .selectCandidate(candidateId)
              .syncToSelectedCandidate()
              .prepareForReceiptReview();
        });
      case ReceiptCandidatePickerSelectionKind.manualEntry:
        await _openManualProductEntry(itemId);
    }
  }

  Future<void> _openManualProductEntry(String itemId) async {
    if (_isSaving) {
      return;
    }
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return;
    }
    final resolver = ref.read(receiptReviewCandidateResolutionServiceProvider);
    final result =
        await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
          context: context,
          args: ManualProductSearchRouteArgs.manualProduct(
            item: _items[index].item,
            includeStoreInSearch: false,
            includeWeightInSearch: false,
          ),
        );
    if (!mounted || _isSaving || result == null) {
      return;
    }

    _replaceDraftByItemId(itemId, (draft) {
      return resolver.applyManualProductResult(
        draft: draft,
        item: result.item,
        selectedProduct: result.selectedProduct,
        selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
      );
    });
  }

  Future<ReceiptReviewItemDraft?> _prepareDraftForCandidateSelection(
    String itemId,
  ) async {
    final draft = _draftForItemId(itemId);
    if (draft == null) {
      return null;
    }
    if (!draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.hasCandidates || _candidateResolvedItemIds.contains(itemId)) {
      return draft;
    }

    final resolver = ref.read(receiptReviewCandidateResolutionServiceProvider);
    return _resolveCandidatesForItem(
      itemId,
      resolver: resolver,
      showLoading: true,
    );
  }

  Future<void> _resolveCandidatesLazily() async {
    final resolver = ref.read(receiptReviewCandidateResolutionServiceProvider);
    final itemIds = _pendingCandidateItemIds();
    for (var index = 0; mounted && index < itemIds.length;) {
      final nextIndex = index + _lazyCandidateResolutionConcurrency;
      final endIndex = nextIndex < itemIds.length ? nextIndex : itemIds.length;
      final batchItemIds = itemIds.sublist(index, endIndex);
      index = endIndex;
      await Future.wait(
        <Future<ReceiptReviewItemDraft?>>[
          for (final itemId in batchItemIds)
            _resolveCandidatesForItem(itemId, resolver: resolver),
        ],
      );
    }
  }

  List<String> _pendingCandidateItemIds() {
    return <String>[
      for (final draft in _items)
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
    required ReceiptReviewCandidateResolutionService resolver,
    bool showLoading = false,
  }) {
    final pendingFuture = _candidateResolutionFutures[itemId];
    if (pendingFuture != null) {
      if (showLoading) {
        _setCandidateLoadingItemId(itemId);
      }
      return pendingFuture.whenComplete(() {
        if (showLoading) {
          _clearCandidateLoadingItemId(itemId);
        }
      });
    }

    final future = _runCandidateResolution(itemId, resolver: resolver);
    _candidateResolutionFutures[itemId] = future;
    if (showLoading) {
      _setCandidateLoadingItemId(itemId);
    }

    return future.whenComplete(() {
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
    final draft = _draftForItemId(itemId);
    if (draft == null || !draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.hasCandidates || _candidateResolvedItemIds.contains(itemId)) {
      return draft;
    }

    final lookupItem = draft.item;
    final resolvedDraft = await resolver.resolveDraftCandidates(draft);
    if (!mounted) {
      return null;
    }
    final currentIndex = _indexForItemId(itemId);
    if (currentIndex < 0) {
      return null;
    }

    final currentDraft = _items[currentIndex];
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
    setState(() {
      _candidateResolvedItemIds.add(itemId);
      _items[currentIndex] = nextDraft;
    });
    return nextDraft;
  }

  void _setCandidateLoadingItemId(String itemId) {
    if (!mounted || _candidateLoadingItemId == itemId) {
      return;
    }
    setState(() {
      _candidateLoadingItemId = itemId;
    });
  }

  void _clearCandidateLoadingItemId(String itemId) {
    if (!mounted || _candidateLoadingItemId != itemId) {
      return;
    }
    setState(() {
      _candidateLoadingItemId = null;
    });
  }

  int _indexForItemId(String itemId) {
    return _items.indexWhere((draft) => draft.item.id == itemId);
  }

  ReceiptReviewItemDraft? _draftForItemId(String itemId) {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return null;
    }
    return _items[index];
  }

  void _replaceDraftByItemId(
    String itemId,
    ReceiptReviewItemDraft Function(ReceiptReviewItemDraft draft) transform,
  ) {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return;
    }
    final currentDraft = _items[index];
    final nextDraft = transform(currentDraft);
    final shouldInvalidateCandidateResolution =
        !hasSameReceiptReviewCandidateLookupInput(
          currentDraft.item,
          nextDraft.item,
        );
    setState(() {
      if (shouldInvalidateCandidateResolution) {
        _candidateResolvedItemIds.remove(itemId);
        _candidateResolutionFutures.remove(itemId)?.ignore();
        if (_candidateLoadingItemId == itemId) {
          _candidateLoadingItemId = null;
        }
      }
      _items[index] = nextDraft;
    });
  }

  Future<void> _openReceiptPreview() async {
    final l10n = AppLocalizations.of(context)!;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.inventoryReceiptReviewCancelAction,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      pageBuilder: (dialogContext, primaryAnimation, secondaryAnimation) {
        return InventoryReceiptPreviewDialog(
          receiptPreviewBytes: widget.receiptPreviewBytes,
        );
      },
    );
  }

  Future<void> _saveReviewedItems() async {
    if (!_canSave) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      await widget.onSaveTap(List<ReceiptReviewItemDraft>.from(_items));
    } on Object catch (error, stackTrace) {
      appLog(
        'Receipt review save failed',
        name: _receiptReviewSheetLogName,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  NumberFormat _currencyFormat(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return buildCurrencyFormat(
      locale: locale,
      currencyCode: resolveSharedCurrencyCode(
        _items.map((draft) => draft.item.currencyCode),
      ),
    );
  }

  Future<InventoryItem?> _showItemEditor(InventoryItem item) async {
    return showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: item);
      },
    );
  }

  void _toggleItemConfirmed(String itemId) {
    if (_isSaving) {
      return;
    }
    final draft = _draftForItemId(itemId);
    if (draft == null || !draft.canBeSavedToInventory) {
      return;
    }
    if (draft.isConfirmed) {
      _replaceDraftByItemId(itemId, (currentDraft) {
        return currentDraft.copyWith(isConfirmed: false);
      });
      return;
    }
    if (!draft.canConfirmReceiptReview) {
      return;
    }

    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(
        isConfirmed: true,
        selectionNeedsReview: false,
        weightNeedsAttention: false,
      );
    });
    _scrollToNextPendingItem(afterItemId: itemId);
  }

  void _scrollToNextPendingItem({required String afterItemId}) {
    final currentIndex = _indexForItemId(afterItemId);
    if (currentIndex < 0) {
      return;
    }

    String? nextItemId;
    for (var index = currentIndex + 1; index < _items.length; index++) {
      final draft = _items[index];
      if (draft.canBeSavedToInventory && !draft.isConfirmed) {
        nextItemId = draft.item.id;
        break;
      }
    }
    if (nextItemId == null) {
      for (final draft in _items) {
        if (draft.canBeSavedToInventory && !draft.isConfirmed) {
          nextItemId = draft.item.id;
          break;
        }
      }
    }
    if (nextItemId == null) {
      return;
    }

    final context = _itemKeys[nextItemId]?.currentContext;
    if (context == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.32,
        ),
      );
    });
  }

  GlobalKey _itemKeyFor(String itemId) {
    return _itemKeys.putIfAbsent(itemId, GlobalKey.new);
  }
}
