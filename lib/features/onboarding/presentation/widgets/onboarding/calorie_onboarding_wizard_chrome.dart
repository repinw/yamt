import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Top progress and bottom action chrome for the onboarding wizard.
class CalorieOnboardingWizardChrome extends StatelessWidget {
  /// Creates onboarding wizard chrome.
  const CalorieOnboardingWizardChrome({
    required this.isKeyboardVisible,
    required this.progress,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  /// Whether the keyboard is covering the lower screen area.
  final bool isKeyboardVisible;

  /// Progress bar value.
  final double progress;

  /// Bottom action label.
  final String nextLabel;

  /// Handles back navigation.
  final VoidCallback onBack;

  /// Handles forward navigation.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          _TopChrome(
            progress: progress,
            onBack: onBack,
          ),
          if (!isKeyboardVisible)
            _BottomChrome(
              nextLabel: nextLabel,
              onNext: onNext,
            ),
        ],
      ),
    );
  }
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.progress,
    required this.onBack,
  });

  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ColoredBox(
        color: theme.canvasColor.withValues(alpha: 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onBack,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.nextLabel,
    required this.onNext,
  });

  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.canvasColor.withValues(alpha: 0),
              theme.canvasColor,
              theme.canvasColor,
            ],
            stops: const [0.0, 0.2, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.lg,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
        ),
        child: FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nextLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
