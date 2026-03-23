import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_sheet.dart';
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
    final index = _indexForItemId(itemId);
    if (index < 0 || _items[index].item.isDiscount) {
      return;
    }

    final editedItem = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: _items[index].item);
      },
    );
    if (!mounted || editedItem == null) {
      return;
    }
    _replaceDraftByItemId(itemId, (draft) => draft.copyWith(item: editedItem));
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
        _replaceDraftByItemId(
          itemId,
          (draft) => draft.selectCandidate(candidateId),
        );
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
    final updatedItem = await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return InventoryReceiptManualProductSheet(item: _items[index].item);
      },
    );
    if (!mounted || updatedItem == null) {
      return;
    }

    _replaceDraftByItemId(
      itemId,
      (draft) => draft.copyWith(item: updatedItem).selectNewItem(),
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
      setState(() {
        _items[currentIndex] = updatedDraft;
      });
      return updatedDraft;
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
    return NumberFormat.currency(locale: locale, symbol: '€');
  }
}
