import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Selectable card for gender choices in onboarding personal info step.
class PersonalInfoGenderCard extends StatelessWidget {
  /// Creates personal info gender card.
  const PersonalInfoGenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.hasError,
    required this.onTap,
    super.key,
  });

  /// The localized sex label.
  final String label;

  /// Icon representing the gender option.
  final IconData icon;

  /// Whether this option is selected.
  final bool isSelected;

  /// Whether an error state should be highlighted.
  final bool hasError;

  /// Callback when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    final backgroundColor = isSelected
        ? primary.withValues(alpha: 0.12)
        : colorScheme.surfaceContainerLow;
    final borderColor = isSelected
        ? primary
        : (hasError ? colorScheme.error : colorScheme.outlineVariant);
    final foregroundColor = isSelected
        ? primary
        : (hasError ? colorScheme.error : colorScheme.onSurface);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GenderIconCircle(
                  icon: icon,
                  isSelected: isSelected,
                  hasError: hasError,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSizes.titleMedium,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    color: foregroundColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderIconCircle extends StatelessWidget {
  const _GenderIconCircle({
    required this.icon,
    required this.isSelected,
    required this.hasError,
  });

  final IconData icon;
  final bool isSelected;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    final iconColor = isSelected
        ? primary
        : (hasError ? colorScheme.error : colorScheme.onSurfaceVariant);
    final circleColor = isSelected
        ? primary.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerHigh;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}
