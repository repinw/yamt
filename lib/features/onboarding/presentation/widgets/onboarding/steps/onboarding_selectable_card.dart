import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared selected-card container for calorie-goal onboarding choices.
class OnboardingSelectableCard extends StatelessWidget {
  /// Creates a tappable choice card.
  const OnboardingSelectableCard({
    required this.isSelected,
    required this.onTap,
    required this.child,
    super.key,
  });

  /// Whether the card is selected.
  final bool isSelected;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Card content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainer,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}
