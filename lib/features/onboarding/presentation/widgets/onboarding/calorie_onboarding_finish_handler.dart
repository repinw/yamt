import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_start_date_controller.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard_controller.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Handles the presentation-side finish action for calorie onboarding.
class CalorieOnboardingFinishHandler {
  /// Creates a finish handler.
  const CalorieOnboardingFinishHandler({
    required CalorieGoalOnboardingFinishFlow finishFlow,
    required CalorieOnboardingWizardController wizardController,
    required CalorieOnboardingStartDateController startDateController,
    DateTime Function()? now,
    Future<void> Function(ProviderContainer container)? markCompleted,
  }) : _finishFlow = finishFlow,
       _wizardController = wizardController,
       _startDateController = startDateController,
       _now = now ?? DateTime.now,
       _markCompleted =
           markCompleted ?? markCalorieGoalOnboardingCompletedFromContainer;

  final CalorieGoalOnboardingFinishFlow _finishFlow;
  final CalorieOnboardingWizardController _wizardController;
  final CalorieOnboardingStartDateController _startDateController;
  final DateTime Function() _now;
  final Future<void> Function(ProviderContainer container) _markCompleted;

  /// Saves onboarding, marks completion, and exits the setup route.
  Future<void> finish({
    required BuildContext context,
    required CalorieGoalCalculatorFormState formState,
    required bool Function() isMounted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final profile = formState.profile;
    final calculation = formState.calculation;
    if (profile == null || calculation == null) {
      _showSaveFailed(messenger, l10n);
      return;
    }

    _wizardController.startSaving();
    final referenceNow = _now();
    final success = await _finishFlow.saveGoal(
      CalorieGoalOnboardingFinishRequest(
        profile: profile,
        dailyGoalKcal: calculation.finalGoalKcal,
        goalStartDate: _startDateController.goalStartDate(referenceNow),
        countGoalStartDayForLearning: _startDateController
            .countGoalStartDayForLearning(),
        catchUpEstimate: _startDateController.catchUpEstimateForSave(),
        placeholderName: l10n.caloriesOnboardingPlaceholderName,
        now: referenceNow,
      ),
    );
    if (!isMounted()) {
      return;
    }

    if (success) {
      await _markCompleted(container);
      if (!isMounted()) {
        return;
      }
      _wizardController.markRouteExitAllowed();
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.homeDiary);
      }
      return;
    }

    _wizardController.stopSavingAfterFailure();
    _showSaveFailed(messenger, l10n);
  }

  void _showSaveFailed(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.caloriesCalculatorSaveFailed)),
      );
  }
}
