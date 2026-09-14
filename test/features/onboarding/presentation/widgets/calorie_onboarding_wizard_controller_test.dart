import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard_controller.dart';

void main() {
  group('CalorieOnboardingWizardController', () {
    test('blocks invalid personal info and shows errors', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        calorieOnboardingWizardControllerProvider.notifier,
      );
      final emptyState = CalorieGoalCalculatorFormState.initial(
        null,
        useEmptyDefaults: true,
      );

      expect(_next(controller, emptyState), 1);
      expect(controller.state.currentStep, CalorieOnboardingStep.personalInfo);
      expect(_next(controller, emptyState), isNull);

      expect(controller.state.currentStep, CalorieOnboardingStep.personalInfo);
      expect(controller.state.showErrors, isTrue);
    });

    test('skips pace step for maintain goals in both directions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        calorieOnboardingWizardControllerProvider.notifier,
      );
      final maintainState = CalorieGoalCalculatorFormState.initial(
        const CalorieCalculatorProfile.defaults(),
      ).copyWith(targetWeightKgText: '70');

      expect(_next(controller, maintainState), 1);
      expect(_next(controller, maintainState), 2);
      expect(_next(controller, maintainState), 3);
      expect(controller.state.currentStep, CalorieOnboardingStep.goalWeight);
      expect(_next(controller, maintainState), 5);

      expect(controller.state.currentStep, CalorieOnboardingStep.trainingDays);
      expect(controller.back(maintainState), 3);
      expect(controller.state.currentStep, CalorieOnboardingStep.goalWeight);
    });

    test(
      'blocks start-date step until external start-date choice is valid',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(
          calorieOnboardingWizardControllerProvider.notifier,
        );
        final maintainState = CalorieGoalCalculatorFormState.initial(
          const CalorieCalculatorProfile.defaults(),
        ).copyWith(targetWeightKgText: '70');

        expect(_next(controller, maintainState), 1);
        expect(_next(controller, maintainState), 2);
        expect(_next(controller, maintainState), 3);
        expect(_next(controller, maintainState), 5);
        expect(
          controller.state.currentStep,
          CalorieOnboardingStep.trainingDays,
        );
        expect(_next(controller, maintainState), 6);
        expect(controller.state.currentStep, CalorieOnboardingStep.info);
        expect(_next(controller, maintainState), 7);

        expect(controller.state.currentStep, CalorieOnboardingStep.startDate);
        expect(_next(controller, maintainState), isNull);
        expect(controller.state.showErrors, isTrue);

        expect(
          _next(
            controller,
            maintainState,
            hasValidStartDateChoice: true,
          ),
          8,
        );
        expect(controller.state.currentStep, CalorieOnboardingStep.ready);
        expect(controller.state.showErrors, isFalse);
      },
    );

    test('tracks saving and route-exit flags', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        calorieOnboardingWizardControllerProvider.notifier,
      );

      // ignore: cascade_invocations, clearer with assertion between mutations.
      controller.startSaving();
      expect(controller.state.isSaving, isTrue);

      controller
        ..stopSavingAfterFailure()
        ..markRouteExitAllowed();
      expect(controller.state.isSaving, isFalse);
      expect(controller.state.allowRouteExit, isTrue);
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
