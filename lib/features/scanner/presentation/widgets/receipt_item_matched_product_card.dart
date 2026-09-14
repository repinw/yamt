import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/presentation/widgets/product_nutrition_summary.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card showing the currently matched product with image, macros,
/// and switch action.
class ReceiptItemMatchedProductCard extends StatelessWidget {
  /// Creates a [ReceiptItemMatchedProductCard].
  const ReceiptItemMatchedProductCard({
    required this.product,
    required this.onClearProduct,
    required this.onSearchProduct,
    super.key,
  });

  /// The matched product candidate, if any.
  final ProductCandidate? product;

  /// Callback to detach the matched product.
  final VoidCallback onClearProduct;

  /// Callback to search or switch to another product.
  final VoidCallback onSearchProduct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProductThumbnail(product, colors),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ??
                          (l10n?.receiptReviewNoProductAssigned ??
                              'Kein Produkt zugewiesen'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(
                      builder: (context) {
                        final parts = <String>[];
                        if (product?.brand != null &&
                            product!.brand!.isNotEmpty) {
                          parts.add(product!.brand!);
                        }
                        if (product?.barcode != null &&
                            product!.barcode!.isNotEmpty) {
                          parts.add(product!.barcode!);
                        }
                        if (parts.isEmpty) return const SizedBox.shrink();
                        return Text(
                          parts.join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (product != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClearProduct,
                  tooltip: l10n?.receiptReviewClearProductMatchTooltip ??
                      'Zuordnung aufheben',
                ),
            ],
          ),
          if (product?.hasNutrition == true) ...[
            const SizedBox(height: AppSpacing.sm),
            ProductNutritionSummary(product: product!),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(
                product != null
                    ? (l10n?.receiptReviewSwitchProductAction ??
                        'Produkt wechseln')
                    : (l10n?.receiptReviewSearchProductAction ??
                        'Produkt suchen'),
              ),
              onPressed: onSearchProduct,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(ProductCandidate? product, ColorScheme colors) {
    final url = product?.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppCachedNetworkImage(
          imageUrl: url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        product != null ? Icons.inventory_2_outlined : Icons.help_outline,
        color: product != null ? Colors.green : colors.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}
