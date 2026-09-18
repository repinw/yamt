import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_intro_controller.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Handles the presentation-side finish action for the calorie intro.
class CalorieIntroFinishHandler {
  /// Creates a finish handler.
  const new({
    required this._finishFlow,
    required this._introController,
    required this._now,
    Future<void> Function(ProviderContainer container)? markCompleted,
  }) : _markCompleted =
           markCompleted ?? markCalorieGoalOnboardingCompletedFromContainer;

  final CalorieGoalOnboardingFinishFlow _finishFlow;
  final CalorieIntroController _introController;
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
    if (profile == null || formState.calculation == null) {
      _showSaveFailed(messenger, l10n);
      return;
    }

    _introController.startSaving();
    final success = await _finishFlow.saveGoal(
      CalorieGoalOnboardingFinishRequest(profile: profile, today: _now()),
    );
    if (!isMounted()) {
      return;
    }

    if (!success) {
      _introController.stopSavingAfterFailure();
      _showSaveFailed(messenger, l10n);
      return;
    }

    await _markCompleted(container);
    if (!isMounted()) {
      return;
    }
    _introController.markRouteExitAllowed();
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.homeDiary);
    }
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
