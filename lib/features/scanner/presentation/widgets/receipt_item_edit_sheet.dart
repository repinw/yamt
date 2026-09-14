import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_candidates_list.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_matched_product_card.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_price_edit_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Modal bottom sheet to inspect and edit a receipt line item.
class ReceiptItemEditSheet extends StatelessWidget {
  /// Creates a [ReceiptItemEditSheet].
  const ReceiptItemEditSheet({
    required this.item,
    required this.onUpdateQuantity,
    required this.onUpdatePrice,
    required this.onSelectCandidate,
    required this.onClearProduct,
    required this.onToggleIgnore,
    required this.onRemove,
    required this.onScanBarcode,
    required this.onSearchProduct,
    super.key,
  });

  /// The item being inspected.
  final ReceiptLineItem item;

  /// Callback when item quantity is modified.
  final ValueChanged<double> onUpdateQuantity;

  /// Callback when item price is modified.
  final ValueChanged<double> onUpdatePrice;

  /// Callback when a product candidate is selected.
  final ValueChanged<ProductCandidate> onSelectCandidate;

  /// Callback to clear matched product.
  final VoidCallback onClearProduct;

  /// Callback to toggle ignore status.
  final VoidCallback onToggleIgnore;

  /// Callback to remove the item completely.
  final VoidCallback onRemove;

  /// Callback to trigger barcode scanner/input.
  final VoidCallback onScanBarcode;

  /// Callback to search product catalog.
  final VoidCallback onSearchProduct;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isIgnored = item.status == ReceiptItemStatus.ignored;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(colors),
              const SizedBox(height: AppSpacing.md),
              _buildHeader(context, colors),
              const SizedBox(height: AppSpacing.lg),
              _buildStepperAndPrice(context, colors),
              const SizedBox(height: AppSpacing.lg),
              _buildMatchedProductCard(colors),
              if (item.candidates.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ReceiptItemCandidatesList(
                  candidates: item.candidates,
                  onSelectCandidate: onSelectCandidate,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildActionButtons(context, colors, isIgnored),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ColorScheme colors) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: colors.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.rawName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          l10n?.receiptReviewOriginalReceiptText ??
              'Originaltext vom Kassenbon',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStepperAndPrice(BuildContext context, ColorScheme colors) {
    final l10n = AppLocalizations.of(context);
    final qty = item.quantity.toString().replaceAll(RegExp(r'\.0$'), '');
    return Row(
      children: [
        Text(
          l10n?.receiptReviewQuantityLabel ?? 'Menge:',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton.outlined(
          icon: const Icon(Icons.remove, size: 16),
          onPressed: item.quantity > 1
              ? () => onUpdateQuantity(item.quantity - 1)
              : null,
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            qty,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add, size: 16),
          onPressed: () => onUpdateQuantity(item.quantity + 1),
          visualDensity: VisualDensity.compact,
        ),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text('${item.totalPrice.toStringAsFixed(2)} €'),
          onPressed: () async {
            final p = await ReceiptPriceEditDialog.show(
              context,
              item.totalPrice,
            );
            if (p != null) onUpdatePrice(p);
          },
        ),
      ],
    );
  }

  Widget _buildMatchedProductCard(ColorScheme colors) =>
      ReceiptItemMatchedProductCard(
        product: item.matchedProduct,
        onClearProduct: onClearProduct,
        onSearchProduct: onSearchProduct,
      );

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colors,
    bool isIgnored,
  ) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton.outlined(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: l10n?.receiptReviewScanBarcode ?? 'Barcode scannen',
          onPressed: onScanBarcode,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.outlined(
          icon: const Icon(Icons.search),
          tooltip: l10n?.receiptReviewSearchProduct ?? 'Produkt suchen',
          onPressed: onSearchProduct,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.outlined(
          icon: Icon(
            isIgnored ? Icons.visibility : Icons.visibility_off_outlined,
            color: isIgnored ? colors.primary : colors.error,
          ),
          tooltip: isIgnored
              ? (l10n?.receiptReviewIncludeItem ?? 'Einbeziehen')
              : (l10n?.receiptReviewIgnoreItem ?? 'Ignorieren'),
          onPressed: onToggleIgnore,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.outlined(
          icon: Icon(Icons.delete_outline, color: colors.error),
          tooltip: l10n?.receiptReviewDeleteItem ?? 'Löschen',
          onPressed: onRemove,
        ),
      ],
    );
  }
}
