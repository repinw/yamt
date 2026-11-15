import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_guide_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

CookRun _run({List<String> steps = const [], bool guide = false}) {
  final run = buildCookRun(
    step: CookRunStep.cook,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    steps: steps,
    lines: [textLine('l-flour', 'Mehl', settlement: const LineIgnored())],
  );
  return guide ? run.useGuide(on: true) : run;
}

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  Future<List<CookRunLine>> added(WidgetTester tester) async => [
    for (final line in (await harness.storedRun(tester, 'recipe-t1')).lines)
      if (line.origin == CookLineOrigin.cooking) line,
  ];

  // Takes the page down, so no listening is left on.
  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('Sprachleiste', () {
    testWidgets('what is said shows as Gehört and becomes new lines', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);
      expect(find.byKey(KochmodusVoiceBar.heardKey), findsNothing);
      expect(find.text(l10n.kochmodusVoiceHintList), findsOneWidget);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      expect(harness.voice.isListening, isTrue);
      expect(find.text(l10n.kochmodusVoiceListening), findsOneWidget);

      // Half a sentence is shown but not taken.
      harness.voice.say('200 g Reis', isFinal: false);
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusVoiceHeard('200 g Reis')), findsOneWidget);
      expect(await added(tester), isEmpty);

      harness.voice.say('200 g Reis und Salz');
      await harness.idle(tester);

      expect(
        find.text(l10n.kochmodusVoiceHeard('200 g Reis und Salz')),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusVoiceSpeak), findsOneWidget);
      final lines = await added(tester);
      expect(lines.map((line) => line.text), ['200 g Reis', 'Salz']);
      expect(lines.every((line) => line.settlement is LineOpen), isTrue);
      expect(find.text('200 g Reis'), findsOneWidget);
      expect(find.text('Salz'), findsOneWidget);
      await close(tester);
    });

    testWidgets('nein takes the line said last away, one by one', (
      tester,
    ) async {
      await open(tester, _run());

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Zwiebeln');
      await harness.idle(tester);
      harness.voice.say('Reis');
      await harness.idle(tester);
      expect((await added(tester)).map((l) => l.text), ['Zwiebeln', 'Reis']);

      harness.voice.say('nein');
      await harness.idle(tester);
      expect((await added(tester)).map((l) => l.text), ['Zwiebeln']);
      expect(find.text('Reis'), findsNothing);

      harness.voice.say('nein');
      await harness.idle(tester);
      expect(await added(tester), isEmpty);

      // Nothing said here is left; the recipe's own line stays.
      harness.voice.say('nein');
      await harness.idle(tester);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).lines.map((l) => l.id),
        ['l-flour'],
      );
      await close(tester);
    });

    testWidgets('typing goes the same way as speaking, and says '
        '"Geschrieben" instead of "Gehört"', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusTypeTitle), findsOneWidget);
      await tester.enterText(
        find.byKey(KochmodusTypeSheet.fieldKey),
        '1,5 kg Mehl, Eier',
      );
      await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
      await harness.idle(tester);

      expect(
        find.text(l10n.kochmodusVoiceTyped('1,5 kg Mehl, Eier')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.kochmodusVoiceHeard('1,5 kg Mehl, Eier')),
        findsNothing,
      );
      expect((await added(tester)).map((l) => l.text), ['1,5 kg Mehl', 'Eier']);
      await close(tester);
    });

    testWidgets('typing nothing adds nothing', (tester) async {
      await open(tester, _run());

      await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
      await harness.idle(tester);
      await tester.enterText(find.byKey(KochmodusTypeSheet.fieldKey), '   ');
      await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusVoiceBar.heardKey), findsNothing);
      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('weiter and Timer do nothing on the list but are heard', (
      tester,
    ) async {
      await open(tester, _run(steps: const ['Eins.', 'Zwei.']));
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('weiter');
      await harness.idle(tester);
      harness.voice.say('Timer 5 Minuten');
      await harness.idle(tester);

      expect(
        find.text(l10n.kochmodusVoiceHeard('Timer 5 Minuten')),
        findsOneWidget,
      );
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.guideStep, 0);
      expect(stored.timers, isEmpty);
      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('a refused microphone says so', (tester) async {
      harness.voice.failure = VoiceSearchFailure.permissionDenied;
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);

      expect(find.text(l10n.cookingVoicePermissionDenied), findsOneWidget);
      expect(find.text(l10n.kochmodusVoiceSpeak), findsOneWidget);
      await close(tester);
    });

    testWidgets('a second tap stops listening', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      expect(harness.voice.isListening, isTrue);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);

      expect(harness.voice.isListening, isFalse);
      expect(harness.voice.starts, 1);
      expect(find.text(l10n.kochmodusVoiceSpeak), findsOneWidget);
      await close(tester);
    });
  });

  group('Sprachleiste im Kochhelfer', () {
    const steps = ['Eins.', 'Zwei.', 'Drei.'];

    testWidgets('weiter and zurück move the step', (tester) async {
      await open(tester, _run(steps: steps, guide: true));
      final l10n = harness.l10n(tester);
      expect(find.text(l10n.kochmodusVoiceHintGuide), findsOneWidget);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('weiter');
      await harness.idle(tester);
      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 1);
      expect(find.text('Zwei.'), findsOneWidget);

      harness.voice.say('zurück');
      await harness.idle(tester);
      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 0);

      // Before the first step there is no way back.
      harness.voice.say('zurück');
      await harness.idle(tester);
      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 0);
      await close(tester);
    });

    testWidgets('weiter on the last step stays', (tester) async {
      await open(tester, _run(steps: steps, guide: true).guideTo(2));

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('weiter');
      await harness.idle(tester);

      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 2);
      expect(find.byKey(KochmodusGuideStep.portionKey), findsOneWidget);
      await close(tester);
    });

    testWidgets('Timer 5 Minuten starts a timer for the step', (tester) async {
      await open(tester, _run(steps: steps, guide: true).guideTo(1));
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Timer 5 Minuten');
      await harness.idle(tester);

      final timer = (await harness.storedRun(
        tester,
        'recipe-t1',
      )).timers.single;
      expect(timer.label, l10n.kochmodusTimerName(1));
      expect(
        timer.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 5))),
      );
      await close(tester);
    });

    testWidgets('a spoken timer adds a second one while the timer of the '
        'step chip runs', (tester) async {
      await open(
        tester,
        _run(
          steps: const ['Eins.', '10 Minuten kochen.'],
          guide: true,
        ).guideTo(1),
      );
      final l10n = harness.l10n(tester);
      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(0)));
      await harness.idle(tester);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).timers.single.label,
        l10n.kochmodusGuideTimerLabel(2),
      );

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Timer 5 Minuten');
      await harness.idle(tester);

      final timers = (await harness.storedRun(tester, 'recipe-t1')).timers;
      expect(timers.map((t) => t.label), [
        l10n.kochmodusGuideTimerLabel(2),
        l10n.kochmodusTimerName(1),
      ]);
      expect(
        timers.last.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 5))),
      );
      await close(tester);
    });

    testWidgets('a second spoken timer is "Timer 2", and the Timer button '
        'goes on with the same numbering', (tester) async {
      await open(tester, _run(steps: steps, guide: true).guideTo(1));
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Timer 5 Minuten');
      await harness.idle(tester);
      harness.voice.say('Timer 7 Minuten');
      await harness.idle(tester);

      var timers = (await harness.storedRun(tester, 'recipe-t1')).timers;
      expect(timers.map((t) => t.label), [
        l10n.kochmodusTimerName(1),
        l10n.kochmodusTimerName(2),
      ]);

      await tester.tap(find.byKey(KochmodusGuideStep.listKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(0)));
      await harness.idle(tester);

      timers = (await harness.storedRun(tester, 'recipe-t1')).timers;
      expect(timers.map((t) => t.label), [
        l10n.kochmodusTimerName(1),
        l10n.kochmodusTimerName(2),
        l10n.kochmodusTimerName(3),
      ]);
      await close(tester);
    });

    testWidgets('nein still takes the line away after a switch to the list', (
      tester,
    ) async {
      await open(tester, _run(steps: steps, guide: true));

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Zwiebeln');
      await harness.idle(tester);
      expect((await added(tester)).map((l) => l.text), ['Zwiebeln']);

      // The cook looks at the whole list, which holds a bar of its own.
      await tester.tap(find.byKey(KochmodusGuideStep.listKey));
      await harness.idle(tester);
      expect(find.byKey(KochmodusCookList.guideKey), findsOneWidget);
      if (!harness.voice.isListening) {
        await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
        await harness.idle(tester);
      }
      harness.voice.say('nein');
      await harness.idle(tester);

      expect(await added(tester), isEmpty);
      expect(find.text('Zwiebeln'), findsNothing);
      await close(tester);
    });

    testWidgets('nein skips a said line that is gone and takes the one before '
        'it', (tester) async {
      await open(tester, _run(steps: steps, guide: true));

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('Zwiebeln');
      await harness.idle(tester);
      harness.voice.say('Reis');
      await harness.idle(tester);
      // The cook removes the last one by hand.
      final reis = (await added(tester)).last.id;
      await tester.tap(find.byKey(KochmodusGuideStep.removeKey(reis)));
      await harness.idle(tester);
      expect((await added(tester)).map((l) => l.text), ['Zwiebeln']);

      harness.voice.say('nein');
      await harness.idle(tester);

      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('an ingredient said in the guide shows as a chip', (
      tester,
    ) async {
      await open(tester, _run(steps: steps, guide: true));

      await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
      await harness.idle(tester);
      harness.voice.say('200 g Sahne');
      await harness.idle(tester);

      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('200 g Sahne'), findsOneWidget);
      await close(tester);
    });
  });
}
