import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft_extensions.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_sheet_controller.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_item_card.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_metadata_overview.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_price_overview.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Scrollable receipt review content with draft item cards and totals.
class InventoryReceiptReviewContent extends StatelessWidget {
  /// Creates receipt review content.
  const InventoryReceiptReviewContent({
    required this.l10n,
    required this.currency,
    required this.priceSummary,
    required this.sheetState,
    required this.itemKeyFor,
    required this.onEditTap,
    required this.onSwitchTap,
    required this.onConfirmTap,
    super.key,
  });

  /// Localizations.
  final AppLocalizations l10n;

  /// Currency formatter.
  final NumberFormat currency;

  /// Price summary.
  final ReceiptReviewPriceSummary priceSummary;

  /// Current sheet state.
  final ReceiptReviewSheetState sheetState;

  /// Resolves stable key for an item id.
  final GlobalKey Function(String itemId) itemKeyFor;

  /// Edit item callback.
  final ValueChanged<String> onEditTap;

  /// Candidate/manual selection callback.
  final ValueChanged<String> onSwitchTap;

  /// Confirm item callback.
  final ValueChanged<String> onConfirmTap;

  @override
  Widget build(BuildContext context) {
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
              (context, index) => _buildReviewItemCard(index),
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

  Widget _buildReviewItemCard(int index) {
    final draft = sheetState.items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InventoryReceiptReviewItemCard(
        key: itemKeyFor(draft.item.id),
        draft: draft,
        index: index,
        currency: currency,
        onEditTap: onEditTap,
        onSwitchTap: onSwitchTap,
        onConfirmTap: () => onConfirmTap(draft.item.id),
        canConfirm: draft.canConfirmReceiptReview,
        isActionLoading: sheetState.candidateLoadingItemId == draft.item.id,
        isEnabled: !sheetState.isSaving,
      ),
    );
  }
}
