import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_intro_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Handles the presentation-side finish action for the calorie intro.
class CalorieIntroFinishHandler {
  /// Creates a finish handler.
  const new({required this._introController});

  final CalorieIntroController _introController;

  /// Saves onboarding and exits the setup route.
  Future<void> finish({
    required BuildContext context,
    required CalorieGoalCalculatorFormState formState,
    required bool Function() isMounted,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final profile = formState.profile;
    if (profile == null || formState.calculation == null) {
      _showSaveFailed(messenger, l10n);
      return;
    }

    final success = await _introController.finish(profile);
    if (!isMounted()) {
      return;
    }
    if (!success) {
      _showSaveFailed(messenger, l10n);
      return;
    }

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
    messenger.showAppSnackBar(
      l10n.caloriesCalculatorSaveFailed,
      tone: AppSnackBarTone.error,
    );
  }
}
