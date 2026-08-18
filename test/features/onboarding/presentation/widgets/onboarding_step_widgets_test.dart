import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'horizontal_dial_wheel.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'onboarding_selectable_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_0_welcome.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_1_personal_info.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_2_activity.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_3_goal_weight.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_4_pace.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_5_info.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_6_start_date.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_7_ready.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('welcome step renders copy and calls next', (tester) async {
    var didContinue = false;
    await _pumpLocalized(
      tester,
      Step0Welcome(onNext: () => didContinue = true),
    );

    expect(find.text('Glad you are here!'), findsOneWidget);

    await tester.tap(find.text("Let's start"));
    await tester.pump();

    expect(didContinue, isTrue);
  });

  testWidgets('welcome step renders login action and calls onLogin', (
    tester,
  ) async {
    var didLogin = false;
    await _pumpLocalized(
      tester,
      Step0Welcome(
        onNext: () {},
        onLogin: () => didLogin = true,
      ),
    );

    expect(find.textContaining('Already registered?'), findsOneWidget);
    expect(find.textContaining('Log in here'), findsOneWidget);

    await tester.tap(find.textContaining('Log in here'));
    await tester.pump();

    expect(didLogin, isTrue);
  });

  testWidgets('personal-info steppers increment and decrement values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step1PersonalInfo(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
            );
          },
        ),
      ),
    );

    final context = tester.element(find.byType(Step1PersonalInfo));
    final container = ProviderScope.containerOf(context, listen: false);

    // Tap plus on Age (first plus button)
    await tester.tap(find.byTooltip('Plus').first);
    await tester.pumpAndSettle();

    expect(container.read(formProvider).ageYearsText, '26');

    // Tap minus on Age (first minus button)
    await tester.tap(find.byTooltip('Minus').first);
    await tester.pumpAndSettle();

    expect(container.read(formProvider).ageYearsText, '25');

    // Tap plus on Height (second plus button)
    await tester.tap(find.byTooltip('Plus').at(1));
    await tester.pumpAndSettle();

    expect(container.read(formProvider).heightCmText, '176');
  });

  testWidgets('personal-info slider updates value on drag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step1PersonalInfo(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
            );
          },
        ),
      ),
    );

    final context = tester.element(find.byType(Step1PersonalInfo));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(find.text('-- years'), findsOneWidget);
    expect(find.text('-- cm'), findsOneWidget);

    final ageDial = find.byType(HorizontalDialWheel).first;
    await tester.drag(ageDial, const Offset(-50, 0));
    await tester.pumpAndSettle();

    expect(container.read(formProvider).ageYearsText.isNotEmpty, isTrue);
  });

  testWidgets('personal-info step updates sex and shows invalid errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step1PersonalInfo(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
              showErrors: true,
            );
          },
        ),
      ),
    );

    final context = tester.element(find.byType(Step1PersonalInfo));
    final container = ProviderScope.containerOf(context, listen: false);

    expect(find.text('Please choose your sex.'), findsNothing);
    expect(find.text('Please enter your age.'), findsOneWidget);
    expect(find.text('Please enter your height.'), findsOneWidget);

    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    expect(container.read(formProvider).sex, CalorieCalculatorSex.male);
  });

  testWidgets('activity step updates the calculator activity option', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step2Activity(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
            );
          },
        ),
      ),
    );

    final context = tester.element(find.byType(Step2Activity));
    final container = ProviderScope.containerOf(context, listen: false);

    final highCard = find.ancestor(
      of: find.text('Very active'),
      matching: find.byType(OnboardingSelectableCard),
    );
    await tester.ensureVisible(highCard);
    await tester.tap(highCard);
    await tester.pumpAndSettle();

    expect(
      container.read(formProvider).activityLevelOption,
      CalorieActivityLevelOption.high,
    );
  });

  testWidgets('goal-weight step shows empty, invalid, and maintain states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final formProvider = calorieGoalCalculatorFormControllerProvider(
      null,
      useEmptyDefaults: true,
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step3GoalWeight(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
              showErrors: true,
            );
          },
        ),
      ),
    );

    expect(find.text('Please enter your weight.'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'abc');
    await tester.enterText(find.byType(TextFormField).at(1), 'nope');
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid weight.'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), '70');
    await tester.enterText(find.byType(TextFormField).at(1), '70');
    await tester.pumpAndSettle();

    expect(
      find.text('You want to maintain your weight. Perfect!'),
      findsOneWidget,
    );
  });

  testWidgets('pace step shows maintain message and no pace warning', (
    tester,
  ) async {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      const CalorieCalculatorProfile.defaults(),
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step4Pace(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
            );
          },
        ),
      ),
    );

    expect(
      find.textContaining('you want to maintain your weight'),
      findsOneWidget,
    );
    expect(find.text('Ambitious Pace'), findsNothing);
  });

  testWidgets('pace step shows warning for aggressive losing pace', (
    tester,
  ) async {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      const CalorieCalculatorProfile.defaults().copyWith(
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.75,
      ),
    );

    await _pumpLocalized(
      tester,
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return Step4Pace(
              state: ref.watch(formProvider),
              notifier: ref.read(formProvider.notifier),
            );
          },
        ),
      ),
    );

    expect(find.text('Ambitious Pace'), findsOneWidget);
    expect(find.textContaining('Losing more than 0.5 kg'), findsOneWidget);
  });

  testWidgets('info step renders all learning-week points', (tester) async {
    await _pumpLocalized(tester, const Step5Info());

    expect(find.textContaining('Your Plan is Ready'), findsOneWidget);
    expect(find.text('Scan Receipts'), findsOneWidget);
    expect(find.text('AI Recognition'), findsOneWidget);
    expect(find.text('Barcode Scanner'), findsOneWidget);
    expect(find.text('The Learning Week'), findsOneWidget);
  });

  testWidgets('start-date step validates and emits nested choices', (
    tester,
  ) async {
    await _pumpLocalized(tester, const _StartDateHarness(showErrors: true));

    expect(find.text('When should your goal start?'), findsOneWidget);

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.goalStartNowOption),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(CalorieGoalOnboardingKeys.todayTrackingExactOption),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieGoalOnboardingKeys.todayTrackingEstimateOption),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(CalorieGoalOnboardingKeys.todayTrackingEstimateOption),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(CalorieGoalOnboardingKeys.catchUpHighOption),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.catchUpLowOption));
    await tester.pumpAndSettle();
    expect(find.text('catchUp=low'), findsOneWidget);

    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.catchUpNormalOption));
    await tester.pumpAndSettle();
    expect(find.text('catchUp=normal'), findsOneWidget);

    await tester.tap(find.byKey(CalorieGoalOnboardingKeys.catchUpHighOption));
    await tester.pumpAndSettle();
    expect(find.text('catchUp=high'), findsOneWidget);
  });

  testWidgets('start-date step shows future date and change action', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      const _StartDateHarness(startNow: false),
    );

    expect(
      find.byKey(CalorieGoalOnboardingKeys.goalStartValue),
      findsOneWidget,
    );

    final changeButton = find.byKey(
      CalorieGoalOnboardingKeys.goalStartChangeButton,
    );
    await tester.ensureVisible(changeButton);
    await tester.tap(changeButton);
    await tester.pump();
    expect(find.text('changeRequests=1'), findsOneWidget);
  });

  testWidgets('start-date step asks for today tracking when starting now', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      const _StartDateHarness(startNow: true, showErrors: true),
    );

    expect(find.text('How will you track today?'), findsOneWidget);
  });

  testWidgets('ready step renders calculation, warning, and finish action', (
    tester,
  ) async {
    var didFinish = false;
    await _pumpLocalized(
      tester,
      Step7Ready(
        isSaving: false,
        calculation: const CalorieGoalCalculationResult(
          bmrKcal: 1500,
          tdeeKcal: 1800,
          expectedActivityKcal: 300,
          dailyAdjustmentKcal: 700,
          finalGoalKcal: 1200,
          wasClampedToMinimum: true,
        ),
        onFinish: () => didFinish = true,
      ),
    );

    expect(find.text('Results'), findsOneWidget);
    expect(find.textContaining('daily target cannot go below'), findsOneWidget);

    final finishButton = find.text("Let's go");
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pump();

    expect(didFinish, isTrue);
  });

  testWidgets('ready step disables finish while saving', (tester) async {
    var didFinish = false;
    await _pumpLocalized(
      tester,
      Step7Ready(
        isSaving: true,
        calculation: null,
        onFinish: () => didFinish = true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(didFinish, isFalse);
  });
}

Future<void> _pumpLocalized(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

class _StartDateHarness extends StatefulWidget {
  const _StartDateHarness({
    this.startNow,
    this.showErrors = false,
  });

  final bool? startNow;
  final bool showErrors;

  @override
  State<_StartDateHarness> createState() => _StartDateHarnessState();
}

class _StartDateHarnessState extends State<_StartDateHarness> {
  bool? _startNow;
  CalorieGoalOnboardingTodayTracking? _todayMode;
  CalorieGoalOnboardingCatchUpEstimate _catchUpEstimate =
      CalorieGoalOnboardingCatchUpEstimate.normal;
  int _changeRequests = 0;

  @override
  void initState() {
    super.initState();
    _startNow = widget.startNow;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Step6StartDate(
            startNow: _startNow,
            todayMode: _todayMode,
            catchUpEstimate: _catchUpEstimate,
            futureGoalStartDate: DateTime(2026, 5, 14),
            showErrors: widget.showErrors,
            onStartNowChanged: (value) {
              setState(() {
                _startNow = value;
                if (!value) {
                  _todayMode = null;
                }
              });
            },
            onTodayModeChanged: (value) {
              setState(() => _todayMode = value);
            },
            onCatchUpEstimateChanged: (value) {
              setState(() => _catchUpEstimate = value);
            },
            onFutureGoalStartChangeRequested: () {
              setState(() => _changeRequests += 1);
            },
          ),
        ),
        Text('startNow=$_startNow'),
        Text('todayMode=${_todayMode?.name ?? 'none'}'),
        Text('catchUp=${_catchUpEstimate.name}'),
        Text('changeRequests=$_changeRequests'),
      ],
    );
  }
}
