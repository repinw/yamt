import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/holo_foil_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_fire.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_menu.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_goal_raise_prompt.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';
import '../../../../calories/support/fake_calories_repositories.dart';
import '../../../../health/support/fake_health_steps_service.dart';

const _ready = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

void main() {
  final today = DateTime(2026, 6, 15);

  Future<void> pumpCard(
    WidgetTester tester, {
    DateTime? day,
    bool stepsOn = true,
    int? Function(DateTime day)? stepsOf,
    double textScale = 1,
    int? goal,
    DateTime? weekStart,
    bool asksToRaise = false,
    bool motion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            MemoryAppPreferences(
              initialInts: {
                if (stepsOn) healthStepsPreferenceKey: 1,
                'health_steps_goal_v1': ?goal,
                // The goal stood before the run week began, so a met week
                // before it asks to raise the goal.
                if (asksToRaise) 'health_steps_goal_since_v1': 20260601,
              },
            ),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 15, 12)),
          healthConnectionServiceProvider.overrideWithValue(
            FakeHealthConnectionService(_ready),
          ),
          healthStepsServiceProvider.overrideWithValue(
            FakeHealthStepsService(stepsOf: stepsOf),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            // Without motion, so the fire of a card at twice its goal
            // stands still and the page settles.
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: !motion,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: DiaryStepsCard(day: day ?? today, weekStart: weekStart),
          ),
        ),
      ),
    );
    // A burning card never settles.
    if (motion) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// The card's line of text: the number and what follows it.
  String cardText(WidgetTester tester) => tester
      .widget<Text>(find.byKey(DiaryStepsCard.valueKey))
      .textSpan!
      .toPlainText();

  /// Whether the card shines as a holo trophy.
  bool shines(WidgetTester tester) =>
      tester.widget<HoloFoilCard>(find.byType(HoloFoilCard)).enabled;

  /// Heights of the fills of the week bars, first day first.
  List<double> barFills(WidgetTester tester) => [
    for (final slot in tester.widgetList<Container>(
      find.descendant(
        of: find.byKey(DiaryStepsCard.cardKey),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.child is Container,
        ),
      ),
    ))
      tester
          .getSize(
            find.descendant(
              of: find.byWidget(slot),
              matching: find.byWidget(slot.child!),
            ),
          )
          .height,
  ];

  testWidgets('shows the steps of the day and no bars without a run week', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(cardText(tester), '8.432 Schritte');
    expect(find.bySemanticsLabel('8432 Schritte'), findsOneWidget);
    expect(barFills(tester), isEmpty);
    expect(find.byKey(DiaryStepsCard.goalLineKey), findsNothing);
  });

  testWidgets('the run week has seven slots that fill up to today', (
    tester,
  ) async {
    // The week runs from Thursday June 11 to Wednesday June 17.
    await pumpCard(
      tester,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (day) => day == today ? 2000 : 4000,
    );

    final fills = barFills(tester);
    expect(fills, hasLength(7));
    expect(fills.sublist(0, 4), everyElement(22));
    expect(fills[4], 11);
    expect(fills.sublist(5), everyElement(0));
  });

  testWidgets('a goal names itself, fills its line and scales the bars', (
    tester,
  ) async {
    await pumpCard(
      tester,
      goal: 10000,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (day) => day == today ? 2500 : 20000,
    );

    expect(cardText(tester), '2.500 / 10.000');
    expect(find.bySemanticsLabel('2500 von 10000 Schritten'), findsOneWidget);
    final line = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byKey(DiaryStepsCard.goalLineKey),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(line.widthFactor, 0.25);
    final fills = barFills(tester);
    // A day over the goal fills its slot, no more.
    expect(fills.first, 22);
    expect(fills[4], 5.5);
  });

  testWidgets('today at the goal keeps its ink, earlier days take the accent', (
    tester,
  ) async {
    await pumpCard(
      tester,
      goal: 1000,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (_) => 1500,
    );

    final colors = [
      for (final slot in tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(DiaryStepsCard.cardKey),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.child is Container,
          ),
        ),
      ))
        ((slot.child! as Container).decoration! as BoxDecoration).color,
    ];
    expect(colors[4], isNot(colors[3]));
    expect(colors.sublist(0, 4).toSet(), hasLength(1));
  });

  testWidgets('a day of a clock change week keeps its slot', (tester) async {
    // Summer time starts on Sunday March 29; the week starts on the Thursday
    // before, so Monday March 30 is its fifth day.
    await pumpCard(
      tester,
      day: DateTime(2026, 3, 30),
      weekStart: DateTime(2026, 3, 26),
      stepsOf: (day) => day == DateTime(2026, 3, 30) ? 1000 : 2000,
    );

    expect(barFills(tester)[4], 11);
  });

  testWidgets('the card shines from the goal on and burns at twice the goal', (
    tester,
  ) async {
    await pumpCard(tester, goal: 5000, stepsOf: (_) => 4999);
    expect(shines(tester), isFalse);
    expect(find.byKey(DiaryStepsCard.fireKey), findsNothing);

    await pumpCard(tester, goal: 5000, stepsOf: (_) => 5000);
    expect(shines(tester), isTrue);
    expect(find.byKey(DiaryStepsCard.fireKey), findsNothing);

    // The fire takes the gold's place.
    await pumpCard(tester, goal: 5000, stepsOf: (_) => 10000);
    expect(find.byType(HoloFoilCard), findsNothing);
    expect(find.byKey(DiaryStepsCard.emberKey), findsOneWidget);
    expect(find.byKey(DiaryStepsCard.fireKey), findsOneWidget);
    expect(find.byType(DiaryStepsFireLine), findsOneWidget);
  });

  testWidgets('with motion the fire keeps running and stops with the card', (
    tester,
  ) async {
    await pumpCard(tester, goal: 5000, stepsOf: (_) => 10000, motion: true);
    expect(find.byKey(DiaryStepsCard.emberKey), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('without a goal the card never shines', (tester) async {
    await pumpCard(tester, stepsOf: (_) => 50000);

    expect(shines(tester), isFalse);
  });

  testWidgets('a tap opens the menu, where a picked goal reaches the card', (
    tester,
  ) async {
    await pumpCard(tester);
    String menuGoal() =>
        tester.widget<Text>(find.byKey(DiaryStepsCardMenu.goalKey)).data!;

    await tester.tap(find.byKey(DiaryStepsCard.cardKey));
    await tester.pumpAndSettle();
    expect(menuGoal(), 'Kein Ziel');
    expect(
      tester
          .widget<IconButton>(find.byKey(DiaryStepsCardMenu.lessKey))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(DiaryStepsCardMenu.presetKey(10000)));
    await tester.pumpAndSettle();
    expect(menuGoal(), '10.000');
    expect(cardText(tester), '8.432 / 10.000');

    // Minus and plus move the goal in steps of 500.
    await tester.tap(find.byKey(DiaryStepsCardMenu.lessKey));
    await tester.pumpAndSettle();
    expect(cardText(tester), '8.432 / 9.500');
    await tester.tap(find.byKey(DiaryStepsCardMenu.moreKey));
    await tester.tap(find.byKey(DiaryStepsCardMenu.moreKey));
    await tester.pumpAndSettle();
    expect(cardText(tester), '8.432 / 10.500');

    await tester.tap(find.byKey(DiaryStepsCardMenu.noGoalKey));
    await tester.pumpAndSettle();
    expect(cardText(tester), '8.432 Schritte');

    // Without a goal the plus starts at the first usual goal.
    await tester.tap(find.byKey(DiaryStepsCardMenu.moreKey));
    await tester.pumpAndSettle();
    expect(menuGoal(), '5.000');
  });

  testWidgets('plus stops at the highest goal of the menu', (tester) async {
    await pumpCard(tester, goal: 49900);

    await tester.tap(find.byKey(DiaryStepsCard.cardKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryStepsCardMenu.moreKey));
    await tester.pumpAndSettle();

    expect(cardText(tester), '8.432 / 50.000');
    expect(
      tester
          .widget<IconButton>(find.byKey(DiaryStepsCardMenu.moreKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets('minus under one step removes the goal', (tester) async {
    await pumpCard(tester, goal: 500);

    await tester.tap(find.byKey(DiaryStepsCard.cardKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryStepsCardMenu.lessKey));
    await tester.pumpAndSettle();

    expect(cardText(tester), '8.432 Schritte');
  });

  testWidgets('the menu switch takes the steps out of the diary', (
    tester,
  ) async {
    await pumpCard(tester);

    await tester.tap(find.byKey(DiaryStepsCard.cardKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryStepsCardMenu.showSwitchKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryStepsCardMenu.menuKey), findsNothing);
    expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
  });

  testWidgets('after a met week today asks to raise the goal; yes raises it', (
    tester,
  ) async {
    await pumpCard(
      tester,
      goal: 5000,
      asksToRaise: true,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (_) => 6000,
    );

    expect(
      find.textContaining('100 Schritte täglich mehr machen?'),
      findsOneWidget,
    );
    expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
    await tester.tap(find.byKey(DiaryStepsGoalRaisePrompt.yesKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryStepsGoalRaisePrompt.promptKey), findsNothing);
    expect(cardText(tester), '6.000 / 5.100');
  });

  testWidgets('no keeps the goal and takes the question away', (tester) async {
    await pumpCard(
      tester,
      goal: 5000,
      asksToRaise: true,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (_) => 6000,
    );

    await tester.tap(find.byKey(DiaryStepsGoalRaisePrompt.noKey));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryStepsGoalRaisePrompt.promptKey), findsNothing);
    expect(cardText(tester), '6.000 / 5.000');
  });

  testWidgets('an earlier day never asks', (tester) async {
    await pumpCard(
      tester,
      day: DateTime(2026, 6, 14),
      goal: 5000,
      asksToRaise: true,
      weekStart: DateTime(2026, 6, 11),
      stepsOf: (_) => 6000,
    );

    expect(find.byKey(DiaryStepsGoalRaisePrompt.promptKey), findsNothing);
  });

  testWidgets('shows nothing while steps are off', (tester) async {
    await pumpCard(tester, stepsOn: false);

    expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
  });

  testWidgets('shows nothing on a day ahead', (tester) async {
    await pumpCard(tester, day: DateTime(2026, 6, 16));

    expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
  });

  testWidgets('shows nothing when Health has no steps for the day', (
    tester,
  ) async {
    await pumpCard(tester, stepsOf: (_) => null);

    expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
  });

  testWidgets('shows a dash when the steps cannot be read', (tester) async {
    await pumpCard(tester, stepsOf: (_) => throw StateError('locked'));

    expect(cardText(tester), '– Schritte');
    expect(
      find.bySemanticsLabel('Schritte konnten nicht gelesen werden'),
      findsOneWidget,
    );
  });

  testWidgets('a long number fits a narrow phone at the largest text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(
      tester,
      stepsOf: (_) => 123456,
      textScale: 3,
      goal: 10000,
      weekStart: DateTime(2026, 6, 11),
    );

    expect(tester.takeException(), isNull);
  });
}
