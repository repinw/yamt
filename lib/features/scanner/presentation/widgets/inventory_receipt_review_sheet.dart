import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
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

  late final List<ReceiptReviewItemDraft> _items;
  late final ReceiptReviewMetadata _receiptMetadata;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          for (final entry in _items.indexed) ...[
            InventoryReceiptReviewItemCard(
              key: _itemKeyFor(entry.$2.item.id),
              draft: entry.$2,
              index: entry.$1,
              currency: currency,
              onEditTap: _openItemEditor,
              onSwitchTap: _openCandidatePicker,
              onConfirmTap: () => _toggleItemConfirmed(entry.$2.item.id),
              canConfirm: entry.$2.canConfirmReceiptReview,
              isActionLoading: _candidateLoadingItemId == entry.$2.item.id,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
          InventoryReceiptReviewPriceOverview(
            totalPrice: priceSummary.totalPrice,
            storablePrice: priceSummary.storablePrice,
            excludedPrice: priceSummary.excludedPrice,
            currency: currency,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    final draft = _draftForItemId(itemId);
    if (draft == null || draft.item.isDiscount) {
      return;
    }

    final editedItem = await _showItemEditor(draft.item);
    if (!mounted || editedItem == null) {
      return;
    }

    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(item: editedItem).prepareForReceiptReview();
    });
  }

  Future<void> _openCandidatePicker(String itemId) async {
    if (_candidateLoadingItemId != null) {
      return;
    }

    final draft = await _prepareDraftForCandidateSelection(itemId);
    if (!mounted || draft == null || !draft.canBeSavedToInventory) {
      return;
    }

    final selection =
        await showModalBottomSheet<ReceiptCandidatePickerSelection>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return InventoryReceiptCandidatePickerSheet(draft: draft);
          },
        );
    if (!mounted || selection == null) {
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
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return;
    }
    final result =
        await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
          context: context,
          args: ManualProductSearchRouteArgs.manualProduct(
            item: _items[index].item,
            includeStoreInSearch: false,
            includeWeightInSearch: false,
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final matcher = ref.read(globalFoodItemMatcherProvider);
    _replaceDraftByItemId(itemId, (draft) {
      final selectedProduct = result.selectedProduct;
      final selectedGlobalFoodItemId = result.selectedGlobalFoodItemId;
      if (selectedProduct == null && selectedGlobalFoodItemId == null) {
        return draft
            .copyWith(item: result.item)
            .selectNewItem()
            .prepareForReceiptReview();
      }

      final scannedCandidate = selectedProduct != null
          ? matcher.candidateFromExternalResult(selectedProduct)
          : result.item.toRecentReceiptReviewCandidate(
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
            item: result.item,
            candidates: mergedCandidates,
            selectionNeedsReview: false,
          )
          .selectCandidate(scannedCandidate.item.id);
      return updatedDraft.prepareForReceiptReview();
    });
  }

  Future<ReceiptReviewItemDraft?> _prepareDraftForCandidateSelection(
    String itemId,
  ) async {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return null;
    }
    final draft = _items[index];
    if (!draft.canBeSavedToInventory) {
      return null;
    }
    if (draft.hasCandidates) {
      return draft;
    }

    setState(() {
      _candidateLoadingItemId = itemId;
    });

    try {
      final matcher = ref.read(globalFoodItemMatcherProvider);
      final candidates = await matcher.findCandidates(draft.item);
      if (!mounted) {
        return null;
      }
      final currentIndex = _indexForItemId(itemId);
      if (currentIndex < 0) {
        return null;
      }

      final updatedDraft = draft
          .copyWith(candidates: candidates)
          .applyAutomaticSelection(
            matcher.defaultSelectionFor(candidates),
            selectionNeedsReview: matcher.defaultSelectionNeedsReviewFor(
              candidates,
            ),
          );
      final syncedDraft = updatedDraft
          .syncToSelectedCandidate()
          .prepareForReceiptReview();
      setState(() {
        _items[currentIndex] = syncedDraft;
      });
      return syncedDraft;
    } finally {
      if (mounted) {
        setState(() {
          _candidateLoadingItemId = null;
        });
      }
    }
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
    setState(() {
      _items[index] = transform(_items[index]);
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
    await widget.onSaveTap(List<ReceiptReviewItemDraft>.from(_items));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
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
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: item);
      },
    );
  }

  void _toggleItemConfirmed(String itemId) {
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
