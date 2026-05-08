import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Welcome step for calorie onboarding.
class Step0Welcome extends StatelessWidget {
  /// Creates welcome step.
  const Step0Welcome({required this.onNext, super.key});

  /// Called when user continues from welcome.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '👋',
              style: TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.onboardingWelcomeTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingWelcomeText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.onboardingWelcomeAction,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
