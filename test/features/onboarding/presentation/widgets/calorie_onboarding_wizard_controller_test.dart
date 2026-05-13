import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard_controller.dart';

void main() {
  group('CalorieOnboardingWizardController', () {
    test('blocks invalid personal info and shows errors', () {
      final controller = CalorieOnboardingWizardController();
      final emptyState = CalorieGoalCalculatorFormState.initial(
        null,
        useEmptyDefaults: true,
      );

      expect(_next(controller, emptyState), 1);
      expect(controller.currentStep, CalorieOnboardingStep.personalInfo);
      expect(_next(controller, emptyState), isNull);

      expect(controller.currentStep, CalorieOnboardingStep.personalInfo);
      expect(controller.showErrors, isTrue);
    });

    test('skips pace step for maintain goals in both directions', () {
      final controller = CalorieOnboardingWizardController();
      final maintainState = CalorieGoalCalculatorFormState.initial(
        const CalorieCalculatorProfile.defaults(),
      ).copyWith(targetWeightKgText: '70');

      expect(_next(controller, maintainState), 1);
      expect(_next(controller, maintainState), 2);
      expect(_next(controller, maintainState), 3);
      expect(controller.currentStep, CalorieOnboardingStep.goalWeight);
      expect(_next(controller, maintainState), 5);

      expect(controller.currentStep, CalorieOnboardingStep.info);
      expect(controller.back(maintainState), 3);
      expect(controller.currentStep, CalorieOnboardingStep.goalWeight);
    });

    test(
      'blocks start-date step until external start-date choice is valid',
      () {
        final controller = CalorieOnboardingWizardController();
        final maintainState = CalorieGoalCalculatorFormState.initial(
          const CalorieCalculatorProfile.defaults(),
        ).copyWith(targetWeightKgText: '70');

        expect(_next(controller, maintainState), 1);
        expect(_next(controller, maintainState), 2);
        expect(_next(controller, maintainState), 3);
        expect(_next(controller, maintainState), 5);
        expect(_next(controller, maintainState), 6);

        expect(controller.currentStep, CalorieOnboardingStep.startDate);
        expect(_next(controller, maintainState), isNull);
        expect(controller.showErrors, isTrue);

        expect(
          _next(
            controller,
            maintainState,
            hasValidStartDateChoice: true,
          ),
          7,
        );
        expect(controller.currentStep, CalorieOnboardingStep.ready);
        expect(controller.showErrors, isFalse);
      },
    );

    test('tracks saving and route-exit flags', () {
      final controller = CalorieOnboardingWizardController();

      // ignore: cascade_invocations, clearer with assertion between mutations.
      controller.startSaving();
      expect(controller.isSaving, isTrue);

      controller
        ..stopSavingAfterFailure()
        ..markRouteExitAllowed();
      expect(controller.isSaving, isFalse);
      expect(controller.allowRouteExit, isTrue);
    });
  });
}

int? _next(
  CalorieOnboardingWizardController controller,
  CalorieGoalCalculatorFormState formState, {
  bool hasValidStartDateChoice = false,
}) {
  return controller.next(
    formState,
    hasValidStartDateChoice: hasValidStartDateChoice,
  );
}
