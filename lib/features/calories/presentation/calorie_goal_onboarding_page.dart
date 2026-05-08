import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/calorie_onboarding_wizard.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

/// Defines calorie goal onboarding page.
class CalorieGoalOnboardingPage extends ConsumerWidget {
  /// The calorie goal onboarding page.
  const CalorieGoalOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(calorieGoalControllerProvider);
    if (settingsState.isLoading && !settingsState.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CalorieOnboardingWizard(
      initialSettings:
          settingsState.asData?.value ?? const CalorieGoalSettings.empty(),
    );
  }
}
