import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Text(
      brand.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: labelStyle?.copyWith(
        fontSize: AppBrandBadge.fontSize,
        fontWeight: AppBrandBadge.fontWeight,
        letterSpacing: AppBrandBadge.letterSpacing,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
