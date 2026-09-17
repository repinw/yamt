import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_training_days.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'StepTrainingDays defaults to no fixed plan when trainingWeekdays is empty',
    (tester) async {
      await _pumpStepTrainingDays(
        tester,
        profile: const CalorieCalculatorProfile.defaults(),
      );

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'tapping fixed plan selects Mo/Mi/Fr and enables 200 kcal offset',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const profile = CalorieCalculatorProfile.defaults();
      final formProvider = calorieGoalCalculatorFormControllerProvider(profile);

      await _pumpStepTrainingDays(
        tester,
        container: container,
        profile: profile,
      );

      await tester.tap(find.byIcon(Icons.fitness_center_rounded));
      await tester.pumpAndSettle();

      final formState = container.read(formProvider);
      expect(formState.trainingWeekdays, const <int>[1, 3, 5]);
      expect(formState.trainingDayKcalOffset, 200.0);
    },
  );

  testWidgets('tapping no fixed plan clears training days and offset', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final profile = const CalorieCalculatorProfile.defaults().copyWith(
      trainingWeekdays: const <int>[1, 3, 5],
      trainingDayKcalOffset: 200,
    );
    final formProvider = calorieGoalCalculatorFormControllerProvider(profile);

    await _pumpStepTrainingDays(tester, container: container, profile: profile);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    final formState = container.read(formProvider);
    expect(formState.trainingWeekdays, isEmpty);
    expect(formState.trainingDayKcalOffset, 0.0);
  });

  testWidgets('toggling extra kcal switch updates offset between 200 and 0', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final profile = const CalorieCalculatorProfile.defaults().copyWith(
      trainingWeekdays: const <int>[1, 3, 5],
      trainingDayKcalOffset: 200,
    );
    final formProvider = calorieGoalCalculatorFormControllerProvider(profile);

    await _pumpStepTrainingDays(tester, container: container, profile: profile);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    var formState = container.read(formProvider);
    expect(formState.trainingDayKcalOffset, 0.0);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    formState = container.read(formProvider);
    expect(formState.trainingDayKcalOffset, 200.0);
  });
}

Future<void> _pumpStepTrainingDays(
  WidgetTester tester, {
  required CalorieCalculatorProfile profile,
  ProviderContainer? container,
}) async {
  final providerContainer = container ?? ProviderContainer();
  final formProvider = calorieGoalCalculatorFormControllerProvider(profile);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: providerContainer,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(formProvider);
              final notifier = ref.read(formProvider.notifier);
              return SingleChildScrollView(
                child: StepTrainingDays(state: state, notifier: notifier),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
