import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Placeholder shown in the value chip while nothing is picked.
const introFieldEmptyValue = '--';

/// Shared card shell for the onboarding picker fields.
///
/// Renders the bordered container, the icon/label/value header, the picker
/// itself, and an optional validation message.
class IntroFieldCard extends StatelessWidget {
  /// Creates a field card.
  const new({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.errorText,
    required this.child,
    this.expand = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Field label.
  final String label;

  /// Formatted current value shown in the chip.
  final String valueText;

  /// Validation error text.
  final String? errorText;

  /// The picker below the header.
  final Widget child;

  /// Whether the picker takes all height the card gets from its parent.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasError = errorText != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(
          alpha: AppIntroLayout.glassOpacity,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasError ? colors.error : colors.outlineVariant,
          width: AppIntroLayout.cardBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: hasError ? colors.error : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasError ? colors.error : colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        valueText,
                        maxLines: 1,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (expand) Expanded(child: child) else child,
          if (hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
