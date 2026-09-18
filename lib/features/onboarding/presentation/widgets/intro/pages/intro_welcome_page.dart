import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// First intro page. Offers starting the setup or signing in.
class IntroWelcomePage extends StatelessWidget {
  /// Creates the intro welcome page.
  const new({required this.onStart, required this.onLogin, super.key});

  /// Starts the onboarding.
  final VoidCallback onStart;

  /// Opens the authentication page.
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return IntroScrollBody(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.restaurant_menu_rounded,
          size: AppSizes.welcomeIcon,
          color: colors.primary,
        ),
        const SizedBox(height: AppSpacing.xxxxl),
        Text(
          l10n.introWelcomeTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.introWelcomeBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxxl),
        SizedBox(
          height: AppSizes.primaryActionHeight,
          child: FilledButton(
            key: CalorieGoalOnboardingKeys.introStartAction,
            onPressed: onStart,
            child: Text(l10n.introStartAction),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          key: CalorieGoalOnboardingKeys.introLoginAction,
          onPressed: onLogin,
          child: Text(l10n.introLoginAction),
        ),
      ],
    );
  }
}
