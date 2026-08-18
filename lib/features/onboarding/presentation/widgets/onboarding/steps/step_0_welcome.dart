import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Welcome step for calorie onboarding.
class Step0Welcome extends StatelessWidget {
  /// Creates welcome step.
  const Step0Welcome({
    required this.onNext,
    this.onLogin,
    super.key,
  });

  /// Called when user continues from welcome.
  final VoidCallback onNext;

  /// Called when user wants to log in with an existing account.
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingWelcomeText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
          if (onLogin != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onLogin,
              child: Text.rich(
                TextSpan(
                  text: '${l10n.onboardingWelcomeAlreadyHaveAccount} ',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text: l10n.onboardingWelcomeLoginAction,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
