import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_item_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_weight_confirmation.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_page.dart';
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
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_weight_confirmation_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Main receipt review content shown inside the full-screen review flow.
class InventoryReceiptReviewSheet extends ConsumerStatefulWidget {
  const InventoryReceiptReviewSheet({
    super.key,
    required this.items,
    required this.onCancelTap,
    required this.onSaveTap,
    this.receiptPreviewBytes,
  });

  final List<ReceiptReviewItemDraft> items;
  final VoidCallback onCancelTap;
  final Future<void> Function(List<ReceiptReviewItemDraft> items) onSaveTap;
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
  var _isSaving = false;
  String? _candidateLoadingItemId;

  @override
  void initState() {
    super.initState();
    final result = _itemProcessor.process(widget.items);
    _items = result.items;
    _receiptMetadata = result.metadata;
  }

  bool get _canSave {
    if (_isSaving) {
      return false;
    }
    return _items.any((item) => item.canBeSavedToInventory);
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
                    offset: Offset(0, 2),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 32),
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
            draft: entry.$2,
            index: entry.$1,
            currency: currency,
            onEditTap: _openItemEditor,
            onSwitchTap: _openCandidatePicker,
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
      return currentDraft.copyWith(
        item: editedItem,
        requiresWeightConfirmation: currentDraft.requiresWeightConfirmation
            ? !_hasWeight(editedItem)
            : false,
      );
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
          final updatedDraft = draft.selectCandidate(candidateId);
          return updatedDraft.copyWith(
            requiresWeightConfirmation: shouldRequireReceiptWeightConfirmation(
              updatedDraft,
            ),
          );
        });
        if (_draftNeedsWeightConfirmation(_draftForItemId(itemId))) {
          await _confirmWeight(itemId);
        }
      case ReceiptCandidatePickerSelectionKind.manualEntry:
        await _openManualProductEntry(itemId);
      case ReceiptCandidatePickerSelectionKind.aiEnrichment:
        _replaceDraftByItemId(itemId, (draft) => draft.markForAiEnrichment());
    }
  }

  Future<void> _openManualProductEntry(String itemId) async {
    final index = _indexForItemId(itemId);
    if (index < 0) {
      return;
    }
    final result = await Navigator.of(context)
        .push<InventoryReceiptManualProductResult>(
          MaterialPageRoute<InventoryReceiptManualProductResult>(
            builder: (routeContext) {
              return InventoryReceiptManualProductPage(
                item: _items[index].item,
                includeStoreInSearch: false,
                includeWeightInSearch: false,
              );
            },
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
        final updatedDraft = draft.copyWith(item: result.item).selectNewItem();
        return updatedDraft.copyWith(
          requiresWeightConfirmation: shouldRequireReceiptWeightConfirmation(
            updatedDraft,
          ),
        );
      }

      final scannedCandidate = selectedProduct != null
          ? matcher.candidateFromExternalResult(selectedProduct)
          : _candidateFromRecentItem(
              item: result.item,
              globalFoodItemId: selectedGlobalFoodItemId!,
            );
      final mergedCandidates = <GlobalFoodMatchCandidate>[
        scannedCandidate,
        ...draft.candidates.where(
          (candidate) => candidate.item.id != scannedCandidate.item.id,
        ),
      ];
      final updatedDraft = draft.copyWith(
        item: result.item,
        candidates: mergedCandidates,
        selectedGlobalFoodItemId: scannedCandidate.item.id,
        selectionNeedsReview: false,
        requestAiEnrichment: false,
      );
      return updatedDraft.copyWith(
        requiresWeightConfirmation: shouldRequireReceiptWeightConfirmation(
          updatedDraft,
        ),
      );
    });
  }

  GlobalFoodMatchCandidate _candidateFromRecentItem({
    required InventoryItem item,
    required String globalFoodItemId,
  }) {
    return GlobalFoodMatchCandidate(
      item: GlobalFoodItem.create(
        id: globalFoodItemId,
        name: item.name,
        now: item.entryDate,
        brand: item.brand,
        category: item.category,
        barcode: item.barcode,
        imageUrl: item.imageUrl,
        packageWeight: item.weight,
        foodFingerprint: item.resolvedFoodFingerprint,
        nutrition: item.nutrition,
      ),
      score: 100,
      reason: GlobalFoodMatchReason.nameExact,
    );
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

      final updatedDraft = draft.copyWith(
        candidates: candidates,
        selectedGlobalFoodItemId: matcher.defaultSelectionFor(candidates),
        selectionNeedsReview: matcher.defaultSelectionNeedsReviewFor(
          candidates,
        ),
      );
      final syncedDraft = updatedDraft.copyWith(
        requiresWeightConfirmation: shouldRequireReceiptWeightConfirmation(
          updatedDraft,
        ),
      );
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

    while (true) {
      final pendingItemId = _firstItemIdNeedingWeightConfirmation();
      if (pendingItemId == null) {
        break;
      }
      final confirmed = await _confirmWeight(pendingItemId);
      if (!mounted || !confirmed) {
        return;
      }
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

  Future<bool> _confirmWeight(String itemId) async {
    final draft = _draftForItemId(itemId);
    if (draft == null || draft.item.isDiscount) {
      return false;
    }

    final confirmedItem = await showInventoryReceiptWeightConfirmationDialog(
      context: context,
      item: draft.item,
      initialWeight: _weightSuggestionFor(draft),
    );
    if (!mounted || confirmedItem == null) {
      return false;
    }

    _replaceDraftByItemId(itemId, (currentDraft) {
      return currentDraft.copyWith(
        item: confirmedItem,
        requiresWeightConfirmation: false,
      );
    });

    return !_draftNeedsWeightConfirmation(_draftForItemId(itemId));
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

  String? _weightSuggestionFor(ReceiptReviewItemDraft draft) {
    return receiptReviewWeightSuggestion(draft);
  }

  String? _firstItemIdNeedingWeightConfirmation() {
    for (final draft in _items) {
      if (_draftNeedsWeightConfirmation(draft)) {
        return draft.item.id;
      }
    }
    return null;
  }

  bool _draftNeedsWeightConfirmation(ReceiptReviewItemDraft? draft) {
    return draft != null &&
        draft.canBeSavedToInventory &&
        draft.requiresWeightConfirmation;
  }

  bool _hasWeight(InventoryItem item) {
    return normalizeReceiptReviewWeight(item.weight) != null;
  }
}
