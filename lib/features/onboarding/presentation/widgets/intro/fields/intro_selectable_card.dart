import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared selected-card container for calorie-goal onboarding choices.
class IntroSelectableCard extends StatelessWidget {
  /// Creates a tappable choice card.
  const new({
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
        duration: AppIntroLayout.selectionTransition,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(
                  alpha: AppIntroLayout.choiceSelectedOpacity,
                )
              : theme.colorScheme.surfaceContainerLow.withValues(
                  alpha: AppIntroLayout.glassOpacity,
                ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainer,
            width: AppIntroLayout.choiceBorderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
