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
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_sheet_controller.dart';
import 'package:yamt/features/scanner/presentation/'
    'receipt_review_item_action_flow.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_preview_button.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_preview_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_content.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_header.dart';
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
              child: InventoryReceiptReviewContent(
                l10n: l10n,
                currency: currency,
                priceSummary: priceSummary,
                sheetState: sheetState,
                itemKeyFor: _itemKeyFor,
                onEditTap: _openItemEditor,
                onSwitchTap: _openCandidatePicker,
                onConfirmTap: _toggleItemConfirmed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openItemEditor(String itemId) {
    unawaited(_itemActionFlow.openItemEditor(itemId));
  }

  void _openCandidatePicker(String itemId) {
    unawaited(_itemActionFlow.openCandidatePicker(itemId));
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

  ReceiptReviewItemActionFlow get _itemActionFlow {
    return ReceiptReviewItemActionFlow(
      context: context,
      controllerProvider: _controllerProvider,
      isMounted: () => mounted,
    );
  }
}
