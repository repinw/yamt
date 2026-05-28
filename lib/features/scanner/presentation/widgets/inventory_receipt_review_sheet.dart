import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
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
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft_extensions.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_sheet_controller.dart';
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

  late final ReceiptReviewSheetControllerProvider _controllerProvider;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _controllerProvider = receiptReviewSheetControllerProvider(widget.items);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = ref.read(_controllerProvider.notifier);
      unawaited(controller.resolveCandidatesLazily());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetState = ref.watch(_controllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final currency = _currencyFormat(context, sheetState.items);
    final priceSummary = _priceSummaryCalculator.calculate(sheetState.items);
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
                    isSaving: sheetState.isSaving,
                    canSave: sheetState.canSave,
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
                sheetState: sheetState,
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
    required ReceiptReviewSheetState sheetState,
  }) {
    final colors = Theme.of(context).colorScheme;

    if (sheetState.items.isEmpty) {
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
                storeName: sheetState.metadata.storeName,
                receiptDate: sheetState.metadata.receiptDate,
                receiptTimeText: sheetState.metadata.receiptTimeText,
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
                  sheetState: sheetState,
                );
              },
              childCount: sheetState.items.length,
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
    required ReceiptReviewSheetState sheetState,
  }) {
    final draft = sheetState.items[index];
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
        isActionLoading: sheetState.candidateLoadingItemId == draft.item.id,
        isEnabled: !sheetState.isSaving,
      ),
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    final controller = ref.read(_controllerProvider.notifier);
    if (ref.read(_controllerProvider).isSaving) {
      return;
    }
    final draft = controller.draftForItemId(itemId);
    if (draft == null || draft.item.isDiscount) {
      return;
    }

    final editedItem = await _showItemEditor(draft.item);
    if (!mounted || editedItem == null) {
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    if (container.read(_controllerProvider).isSaving) {
      return;
    }

    container
        .read(_controllerProvider.notifier)
        .applyEditedItem(
          itemId,
          editedItem,
        );
  }

  Future<void> _openCandidatePicker(String itemId) async {
    final controller = ref.read(_controllerProvider.notifier);
    final sheetState = ref.read(_controllerProvider);
    if (sheetState.isSaving || sheetState.candidateLoadingItemId != null) {
      return;
    }

    final draft = await controller.prepareDraftForCandidateSelection(itemId);
    if (!mounted || draft == null || !draft.canBeSavedToInventory) {
      return;
    }
    var container = ProviderScope.containerOf(context, listen: false);
    if (container.read(_controllerProvider).isSaving) {
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
    if (!mounted || selection == null) {
      return;
    }
    container = ProviderScope.containerOf(context, listen: false);
    if (container.read(_controllerProvider).isSaving) {
      return;
    }

    switch (selection.kind) {
      case ReceiptCandidatePickerSelectionKind.candidate:
        final candidateId = selection.candidateId;
        if (candidateId == null) {
          return;
        }
        container
            .read(_controllerProvider.notifier)
            .selectCandidate(
              itemId,
              candidateId,
            );
      case ReceiptCandidatePickerSelectionKind.manualEntry:
        await _openManualProductEntry(itemId);
    }
  }

  Future<void> _openManualProductEntry(String itemId) async {
    final controller = ref.read(_controllerProvider.notifier);
    if (ref.read(_controllerProvider).isSaving) {
      return;
    }
    final draft = controller.draftForItemId(itemId);
    if (draft == null) {
      return;
    }
    final result =
        await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
          context: context,
          args: ManualProductSearchRouteArgs.manualProduct(
            item: draft.item,
            includeStoreInSearch: false,
            includeWeightInSearch: false,
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    if (container.read(_controllerProvider).isSaving) {
      return;
    }
    container
        .read(_controllerProvider.notifier)
        .applyManualProductResult(
          itemId: itemId,
          item: result.item,
          selectedProduct: result.selectedProduct,
          selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
        );
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
    final controller = ref.read(_controllerProvider.notifier);
    await controller.saveReviewedItems(widget.onSaveTap);
  }

  NumberFormat _currencyFormat(
    BuildContext context,
    List<ReceiptReviewItemDraft> items,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return buildCurrencyFormat(
      locale: locale,
      currencyCode: resolveSharedCurrencyCode(
        items.map((draft) => draft.item.currencyCode),
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
    final controller = ref.read(_controllerProvider.notifier);
    final nextItemId = controller.toggleItemConfirmed(itemId);
    if (nextItemId == null) {
      return;
    }

    _scrollToItem(nextItemId);
  }

  void _scrollToItem(String nextItemId) {
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
