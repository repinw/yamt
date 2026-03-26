import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBrandBadge.borderRadius),
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colorScheme),
        ),
      ),
      child: Padding(
        padding: AppBrandBadge.padding,
        child: Text(
          brand.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle?.copyWith(
            fontSize: AppBrandBadge.fontSize,
            fontWeight: AppBrandBadge.fontWeight,
            letterSpacing: AppBrandBadge.letterSpacing,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
