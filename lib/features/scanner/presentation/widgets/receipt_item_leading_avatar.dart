import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

/// Leading avatar for a receipt line item displaying product thumbnail
/// and status dot.
class ReceiptItemLeadingAvatar extends StatelessWidget {
  /// Creates a [ReceiptItemLeadingAvatar].
  const ReceiptItemLeadingAvatar({
    required this.status,
    this.imageUrl,
    super.key,
  });

  /// The product image URL if available.
  final String? imageUrl;

  /// The traffic-light status of the receipt line item.
  final ReceiptItemStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AppCachedNetworkImage(
              imageUrl: imageUrl!,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
              ),
              child: _buildIcon(colors, size: 14),
            ),
          ),
        ],
      );
    }
    return _buildIcon(colors, size: 22);
  }

  Widget _buildIcon(ColorScheme colors, {required double size}) =>
      switch (status) {
        ReceiptItemStatus.confirmed =>
          Icon(Icons.check_circle_rounded, color: Colors.green, size: size),
        ReceiptItemStatus.suggested => Icon(
          Icons.auto_awesome_rounded,
          color: Colors.amber.shade700,
          size: size,
        ),
        ReceiptItemStatus.unmatched => Icon(
          Icons.help_outline_rounded,
          color: colors.onSurfaceVariant,
          size: size,
        ),
        ReceiptItemStatus.ignored => Icon(
          Icons.visibility_off_outlined,
          color: colors.outline,
          size: size,
        ),
      };
}
