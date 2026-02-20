import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.brand});

  static const _size = 40.0;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = brand.trim();

    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_size / 2),
        color: colors.secondaryContainer.withValues(alpha: 0.75),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: SizedBox.square(
        dimension: _size,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              normalized.toUpperCase(),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
