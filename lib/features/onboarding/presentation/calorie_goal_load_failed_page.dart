import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Gate shown when the router cannot tell whether the signed-in user finished
/// onboarding, for example offline on a new device. Sending the user into
/// onboarding instead would ask an onboarded user to set up a goal again.
///
/// The router leaves this page as soon as the state loads.
class CalorieGoalLoadFailedPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppInsets.pageLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.calorieGoalLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: CalorieGoalOnboardingKeys.loadFailedRetryAction,
                onPressed: () =>
                    ref.invalidate(calorieGoalOnboardingCompletedProvider),
                child: Text(l10n.calorieGoalLoadRetryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
