import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_intro_controller.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_state.dart';

CalorieGoalCalculatorFormState _formState({
  String weight = '80',
  String targetWeight = '75',
  CalorieGoalMode goalMode = CalorieGoalMode.lose,
}) {
  return CalorieGoalCalculatorFormState.initial(
    null,
    useEmptyDefaults: true,
  ).copyWith(
    sex: CalorieCalculatorSex.female,
    birthDate: DateTime(1996, 1, 5),
    ageYearsText: '30',
    heightCmText: '170',
    weightKgText: weight,
    targetWeightKgText: targetWeight,
    activityLevelOption: CalorieActivityLevelOption.low,
    goalMode: goalMode,
    goalSpeedKgPerWeekText: '0.5',
  );
}

int _pageIndex(CalorieIntroPage page) => CalorieIntroPage.values.indexOf(page);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  CalorieIntroController controller() =>
      container.read(calorieIntroControllerProvider.notifier);

  CalorieIntroState state() => container.read(calorieIntroControllerProvider);

  test('starts on the welcome page without chrome actions', () {
    expect(state().page, 0);
    expect(state().currentPage, CalorieIntroPage.welcome);
    expect(state().showsNextAction, isFalse);
    expect(state().showsBackAction, isFalse);
  });

  test('walks through the story pages', () {
    final form = _formState();

    expect(controller().next(form), 1);
    expect(state().currentPage, CalorieIntroPage.calorieModel);
    expect(state().showsNextAction, isTrue);
    expect(state().showsBackAction, isTrue);
  });

  test('blocks the identity page until gender and age are set', () {
    final form = _formState();
    for (var page = 0; page < _pageIndex(CalorieIntroPage.identity); page++) {
      controller().next(form);
    }
    expect(state().currentPage, CalorieIntroPage.identity);

    final incomplete = CalorieGoalCalculatorFormState.initial(
      null,
      useEmptyDefaults: true,
    );
    expect(controller().next(incomplete), isNull);
    expect(state().showErrors, isTrue);

    expect(controller().next(form), _pageIndex(CalorieIntroPage.body));
    expect(state().showErrors, isFalse);
  });

  test('blocks the target page while the target weight is empty', () {
    final form = _formState();
    for (var page = 0; page < _pageIndex(CalorieIntroPage.target); page++) {
      controller().next(form);
    }
    expect(state().currentPage, CalorieIntroPage.target);

    expect(controller().next(_formState(targetWeight: '')), isNull);
    expect(state().showErrors, isTrue);
  });

  test('skips the pace page when the user wants to maintain weight', () {
    final maintain = _formState(
      targetWeight: '80',
      goalMode: CalorieGoalMode.maintain,
    );
    for (var page = 0; page < _pageIndex(CalorieIntroPage.sport); page++) {
      controller().next(maintain);
    }
    expect(state().currentPage, CalorieIntroPage.sport);

    expect(controller().next(maintain), _pageIndex(CalorieIntroPage.summary));
    expect(controller().back(maintain), _pageIndex(CalorieIntroPage.sport));
  });

  test('tracks saving and route exit flags', () {
    controller().startSaving();
    expect(state().isSaving, isTrue);
    expect(state().showsBackAction, isFalse);

    controller().stopSavingAfterFailure();
    expect(state().isSaving, isFalse);

    controller().markRouteExitAllowed();
    expect(state().allowRouteExit, isTrue);
  });
}
