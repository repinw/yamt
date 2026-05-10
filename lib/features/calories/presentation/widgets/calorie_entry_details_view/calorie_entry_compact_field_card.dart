import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Compact labeled card used by calorie entry detail controls.
class CalorieEntryCompactFieldCard extends StatelessWidget {
  /// Creates a compact field card.
  const CalorieEntryCompactFieldCard({
    required this.label,
    required this.child,
    super.key,
  });

  /// Uppercase label shown above the field.
  final String label;

  /// Field content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
        color: Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.94),
          colors.surface,
        ),
        blurRadius: 18,
        shadowOffset: const Offset(0, 8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            child,
          ],
        ),
      ),
    );
  }
}
