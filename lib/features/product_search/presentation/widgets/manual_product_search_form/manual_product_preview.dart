import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';

/// Data shown in manual product preview.
class InventoryReceiptManualProductPreviewData {
  /// Creates manual product preview data.
  const InventoryReceiptManualProductPreviewData({
    required this.imageUrl,
    required this.name,
    this.brand,
    this.weight,
  });

  /// Product image URL.
  final String? imageUrl;

  /// Product name.
  final String name;

  /// Product brand.
  final String? brand;

  /// Product weight label.
  final String? weight;
}

/// Preview card for currently selected manual product.
class ManualProductPreview extends StatelessWidget {
  /// Creates a manual product preview.
  const ManualProductPreview({
    required this.preview,
    super.key,
  });

  /// Preview data.
  final InventoryReceiptManualProductPreviewData preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = normalizeManualProductText(preview.brand ?? '');
    final weight = normalizeManualProductText(preview.weight ?? '');

    return Container(
      key: const Key('receipt_review_manual_preview'),
      width: double.infinity,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: _PreviewImage(imageUrl: preview.imageUrl),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key: const Key('receipt_review_manual_preview_name'),
                  preview.name,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: const Key('receipt_review_manual_preview_brand'),
                    brand,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (weight != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: const Key('receipt_review_manual_preview_weight'),
                    weight,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedUrl = normalizeProductImageUrl(imageUrl);
    if (resolvedUrl == null) {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: SizedBox.square(
          dimension: 72,
          child: Icon(
            Icons.inventory_2_outlined,
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return AppCachedNetworkImage(
      imageUrl: resolvedUrl,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: SizedBox.square(
            dimension: 72,
            child: Icon(
              Icons.inventory_2_outlined,
              color: colors.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
