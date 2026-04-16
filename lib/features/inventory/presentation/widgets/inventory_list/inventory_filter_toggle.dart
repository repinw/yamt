import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Defines inventory filter toggle.
class InventoryFilterToggle extends StatelessWidget {
  /// The inventory filter toggle.
  const InventoryFilterToggle({
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
    super.key,
    this.description,
    this.icon,
  });

  /// The value.
  final bool value;

  /// The enabled.
  final bool enabled;

  /// The label.
  final String label;

  /// The on changed.
  final ValueChanged<bool> onChanged;

  /// The description.
  final String? description;

  /// The icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = AppInventoryEditorialSurfaces.ghostBorder(colors);
    final iconBackground = value
        ? colors.primary.withValues(alpha: 0.14)
        : colors.surfaceContainerHigh;
    final iconColor = value ? colors.primary : colors.onSurfaceVariant;

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppInventoryEditorialSurfaces.section(colors),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (icon != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? colors.onSurface
                            : colors.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? colors.onSurfaceVariant
                              : colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
