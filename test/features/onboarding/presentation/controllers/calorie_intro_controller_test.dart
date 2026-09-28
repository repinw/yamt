import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/models/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_intro_controller.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_state.dart';

import '../../../../helpers/fake_guest_account.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';

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

final _now = DateTime(2026, 9, 23, 18);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => _now)],
    );
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
    for (var page = 0; page < _pageIndex(CalorieIntroPage.target); page++) {
      controller().next(maintain);
    }
    expect(state().currentPage, CalorieIntroPage.target);

    expect(controller().next(maintain), _pageIndex(CalorieIntroPage.activity));
    expect(controller().back(maintain), _pageIndex(CalorieIntroPage.target));
  });

  test('proposes tomorrow as start day in the evening', () {
    expect(state().startDate, DateTime(2026, 9, 24));
  });

  test('selects another start day as a whole day', () {
    controller().selectStartDate(DateTime(2026, 9, 26, 15, 30));

    expect(state().startDate, DateTime(2026, 9, 26));
  });

  group('finish', () {
    late FakeGuestAccount account;
    late MemoryAppPreferences preferences;
    late FakeCalorieSettingsRepository settingsRepository;

    ProviderContainer finishContainer({bool saves = true}) {
      preferences = MemoryAppPreferences();
      settingsRepository = FakeCalorieSettingsRepository()
        ..saveShouldFail = !saves;
      final logRepository = FakeCalorieLogRepository();
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          appPreferencesProvider.overrideWithValue(preferences),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            FakeBurnWeekRunStateRepository(),
          ),
          ...account.overrides,
        ],
      );
      addTearDown(container.dispose);
      addTearDown(account.dispose);
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      return container;
    }

    Future<List<DateTime>> savedGoalStarts() async {
      final settings = await settingsRepository.readSettings();
      return [
        for (final goal in settings.goalHistory)
          goal.effectiveCountingStartDate,
      ];
    }

    Future<CalorieIntroFinishResult> finish(ProviderContainer container) {
      final subscription = container.listen(
        calorieIntroControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      return container
          .read(calorieIntroControllerProvider.notifier)
          .finish(_formState().profile!);
    }

    test('creates the guest account only when the intro finishes', () async {
      account = FakeGuestAccount();
      final container = finishContainer()..read(calorieIntroControllerProvider);

      expect(account.repository.guestCalls, 0);

      final result = await finish(container);

      expect(result, CalorieIntroFinishResult.finished);
      expect(account.repository.guestCalls, 1);
      expect(await savedGoalStarts(), [DateTime(2026, 9, 24)]);
      expect(
        preferences.getStringSync(
          calorieGoalOnboardingKeyForUser(FakeGuestAccount.guestUserId),
        ),
        calorieGoalOnboardingCompletedValue,
      );
      final state = container.read(calorieIntroControllerProvider);
      expect(state.allowRouteExit, isTrue);
    });

    test('keeps a signed-in account', () async {
      account = FakeGuestAccount(userId: 'signed-in-user');
      final container = finishContainer();

      final result = await finish(container);

      expect(result, CalorieIntroFinishResult.finished);
      expect(account.repository.guestCalls, 0);
      expect(
        preferences.getStringSync(
          calorieGoalOnboardingKeyForUser('signed-in-user'),
        ),
        calorieGoalOnboardingCompletedValue,
      );
    });

    test('keeps the answers when there is no connection', () async {
      account = FakeGuestAccount(signInError: const AuthOfflineException());
      final container = finishContainer();

      expect(await finish(container), CalorieIntroFinishResult.offline);
      expect(await savedGoalStarts(), isEmpty);
      expect(container.read(calorieIntroControllerProvider).isSaving, isFalse);

      account.signInError = null;

      expect(await finish(container), CalorieIntroFinishResult.finished);
      expect(account.repository.guestCalls, 2);
      expect(await savedGoalStarts(), [DateTime(2026, 9, 24)]);
    });

    test('loads a failed data key again on the next attempt', () async {
      account = FakeGuestAccount(userId: 'signed-in-user')
        ..dataKeyError = Exception('key backup unavailable');
      final container = finishContainer();

      expect(await finish(container), CalorieIntroFinishResult.failed);

      account.dataKeyError = null;

      expect(await finish(container), CalorieIntroFinishResult.finished);
    });

    test('stays on the intro when the guest sign-in fails', () async {
      account = FakeGuestAccount(signInError: Exception('sign-in failed'));
      final container = finishContainer();

      final result = await finish(container);

      expect(result, CalorieIntroFinishResult.failed);
      expect(await savedGoalStarts(), isEmpty);
      final state = container.read(calorieIntroControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.allowRouteExit, isFalse);
    });

    test('stays on the intro when the goal is not saved', () async {
      account = FakeGuestAccount();
      final container = finishContainer(saves: false);

      final result = await finish(container);

      expect(result, CalorieIntroFinishResult.failed);
      expect(
        preferences.getStringSync(
          calorieGoalOnboardingKeyForUser(FakeGuestAccount.guestUserId),
        ),
        isNull,
      );
      final state = container.read(calorieIntroControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.allowRouteExit, isFalse);
    });
  });
}
