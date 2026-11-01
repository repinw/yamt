import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_shares_editor.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';
import '../../../../../helpers/time_picker_test_utils.dart';

const _sharesKey = 'diary_meal_shares_v1';
const _timesKey = 'diary_meal_times_v1';

Future<MemoryAppPreferences> _pump(
  WidgetTester tester, {
  String? savedShares,
  String? savedTimes,
  bool use24HourClock = false,
  double targetKcal = 2000,
  double textScale = 1,
}) async {
  final preferences = MemoryAppPreferences(
    initialStrings: {_sharesKey: ?savedShares, _timesKey: ?savedTimes},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The device's clock setting, which the time picker follows too.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: use24HourClock,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DiaryMealSharesEditor(targetKcal: targetKcal),
          ),
        ),
      ),
    ),
  );
  return preferences;
}

String? _part(WidgetTester tester, MealType meal) =>
    tester.widget<Text>(find.byKey(DiaryMealSharesEditor.partKey(meal))).data;

/// The words on the time button with [key], such as "by 9:00 AM".
String? _time(WidgetTester tester, Key key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .data;

String? _timeOf(WidgetTester tester, MealType meal) =>
    _time(tester, DiaryMealSharesEditor.timeKey(meal));

/// Where [percent] of the day sits on the blocks.
Offset _at(WidgetTester tester, int percent) {
  final rect = tester.getRect(find.byKey(DiaryMealSharesEditor.blocksKey));
  const inset = AppBudgetCard.mealSharesHandle / 2;
  return Offset(
    rect.left + inset + percent / 100 * (rect.width - 2 * inset),
    rect.center.dy,
  );
}

Future<void> _drag(WidgetTester tester, int from, int to) async {
  await tester.dragFrom(_at(tester, from), _at(tester, to) - _at(tester, from));
  await tester.pumpAndSettle();
}

/// Taps the time button with [key] and picks [time] in the picker.
Future<void> _pick(WidgetTester tester, Key key, TimeOfDay time) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await pickTimeInOpenPicker(tester, time);
}

void main() {
  group('shares', () {
    testWidgets('lists each meal with its share and kcal', (tester) async {
      await _pump(tester);

      expect(_part(tester, MealType.breakfast), '25 % · 500 kcal');
      expect(_part(tester, MealType.lunch), '35 % · 700 kcal');
      expect(_part(tester, MealType.dinner), '30 % · 600 kcal');
      expect(_part(tester, MealType.snack), '10 % · 200 kcal');
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('fit a small phone with text at $scale', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _pump(tester, targetKcal: 3000, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(_part(tester, MealType.lunch), '35 % · 1,050 kcal');
      });
    }

    testWidgets('a dragged handle moves its border and saves it when let go', (
      tester,
    ) async {
      final preferences = await _pump(tester);

      await _drag(tester, 25, 40);

      expect(_part(tester, MealType.breakfast), '40 % · 800 kcal');
      expect(_part(tester, MealType.lunch), '20 % · 400 kcal');
      expect(preferences.getStringSync(_sharesKey), '40,20,30,10');
    });

    testWidgets('a border pushed onto the next turns the meal off, and a '
        'drag from there brings it back', (tester) async {
      final preferences = await _pump(tester);

      // Lunch's end runs into dinner's end.
      await _drag(tester, 60, 99);

      expect(_part(tester, MealType.dinner), 'Off');
      expect(preferences.getStringSync(_sharesKey), '25,65,0,10');

      // Both borders sit at 90 now; a drag to the right takes dinner's end.
      await _drag(tester, 90, 95);

      expect(_part(tester, MealType.dinner), '5 % · 100 kcal');
      expect(_part(tester, MealType.snack), '5 % · 100 kcal');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a meal at 0 on the edge keeps its handle there', (
      tester,
    ) async {
      final preferences = await _pump(tester, savedShares: '0,60,30,10');
      expect(_part(tester, MealType.breakfast), 'Off');

      await _drag(tester, 0, 20);

      expect(_part(tester, MealType.breakfast), '20 % · 400 kcal');
      expect(preferences.getStringSync(_sharesKey), '20,40,30,10');
    });

    testWidgets('a meal that is off keeps its time button', (tester) async {
      await _pump(tester, savedShares: '0,60,30,10');

      expect(_part(tester, MealType.breakfast), 'Off');
      expect(_timeOf(tester, MealType.breakfast), 'by 9:00 AM');
    });
  });

  group('rows', () {
    testWidgets('on a day without a target show only the share', (
      tester,
    ) async {
      await _pump(tester, targetKcal: 0, savedShares: '0,35,55,10');

      expect(_part(tester, MealType.breakfast), 'Off');
      expect(_part(tester, MealType.lunch), '35 %');
      expect(_part(tester, MealType.dinner), '55 %');
      expect(_part(tester, MealType.snack), '10 %');
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a day with a target show the share and its kcal', (
      tester,
    ) async {
      await _pump(tester, targetKcal: 1500);

      expect(_part(tester, MealType.breakfast), '25 % · 375 kcal');
      expect(_part(tester, MealType.lunch), '35 % · 525 kcal');
    });

    testWidgets('are read by a screen reader one by one, each with its time '
        'button', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      // The semantics of a row are merged into one node, which keeps the
      // time button's tap.
      final lunch = tester
          .getSemantics(
            find.byKey(DiaryMealSharesEditor.partKey(MealType.lunch)),
          )
          .getSemanticsData();
      expect(lunch.label, 'Lunch\n35 % · 700 kcal\nby 1:00 PM');
      expect(lunch.hasAction(SemanticsAction.tap), isTrue);

      final start = tester
          .getSemantics(find.byKey(DiaryMealSharesEditor.startKey))
          .getSemanticsData();
      expect(start.label, 'Day starts\nfrom 6:00 AM');
      expect(start.hasAction(SemanticsAction.tap), isTrue);

      semantics.dispose();
    });
  });

  group('screen reader steps', () {
    testWidgets('a step of a border moves it by 5 percent, shows it and '
        'saves it', (tester) async {
      final semantics = tester.ensureSemantics();
      final preferences = await _pump(tester);

      tester.semantics.increase(
        find.semantics.byLabel('Border between Breakfast and Lunch'),
      );
      await tester.pumpAndSettle();

      expect(_part(tester, MealType.breakfast), '30 % · 600 kcal');
      expect(_part(tester, MealType.lunch), '30 % · 600 kcal');
      expect(preferences.getStringSync(_sharesKey), '30,30,30,10');

      tester.semantics.decrease(
        find.semantics.byLabel('Border between Lunch and Dinner'),
      );
      await tester.pumpAndSettle();

      expect(_part(tester, MealType.lunch), '25 % · 500 kcal');
      expect(_part(tester, MealType.dinner), '35 % · 700 kcal');
      expect(preferences.getStringSync(_sharesKey), '30,25,35,10');

      semantics.dispose();
    });

    testWidgets('stepping a border onto the next turns the meal off', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final preferences = await _pump(tester, savedShares: '25,35,5,35');

      tester.semantics.decrease(
        find.semantics.byLabel('Border between Dinner and Snack'),
      );
      await tester.pumpAndSettle();

      expect(_part(tester, MealType.dinner), 'Off');
      expect(preferences.getStringSync(_sharesKey), '25,35,0,40');

      semantics.dispose();
    });
  });

  group('times', () {
    testWidgets("shows when the day starts and each meal's time", (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Day starts'), findsOneWidget);
      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 6:00 AM');
      expect(_timeOf(tester, MealType.breakfast), 'by 9:00 AM');
      expect(_timeOf(tester, MealType.lunch), 'by 1:00 PM');
      expect(_timeOf(tester, MealType.dinner), 'by 7:00 PM');
      expect(_timeOf(tester, MealType.snack), 'by 9:00 PM');
      for (final name in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('shows saved times', (tester) async {
      await _pump(tester, savedTimes: '330,480,750,1080,1350');

      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 5:30 AM');
      expect(_timeOf(tester, MealType.breakfast), 'by 8:00 AM');
      expect(_timeOf(tester, MealType.lunch), 'by 12:30 PM');
      expect(_timeOf(tester, MealType.dinner), 'by 6:00 PM');
      expect(_timeOf(tester, MealType.snack), 'by 10:30 PM');
    });

    testWidgets('writes the times the way the device clock does', (
      tester,
    ) async {
      await _pump(tester, use24HourClock: true);

      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 06:00');
      expect(_timeOf(tester, MealType.lunch), 'by 13:00');
      expect(_timeOf(tester, MealType.snack), 'by 21:00');
    });

    testWidgets('a time is picked on a 24-hour clock too', (tester) async {
      final preferences = await _pump(tester, use24HourClock: true);

      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.dinner),
        const TimeOfDay(hour: 18, minute: 45),
      );

      expect(_timeOf(tester, MealType.dinner), 'by 18:45');
      expect(preferences.getStringSync(_timesKey), '360,540,780,1125,1260');
    });

    testWidgets('a time button opens the time picker on its time', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(
        find.byKey(DiaryMealSharesEditor.timeKey(MealType.lunch)),
      );
      await tester.pumpAndSettle();

      final picker = tester.widget<TimePickerDialog>(
        find.byType(TimePickerDialog),
      );
      expect(picker.initialTime, const TimeOfDay(hour: 13, minute: 0));

      await cancelOpenTimePicker(tester);

      await tester.tap(find.byKey(DiaryMealSharesEditor.startKey));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        const TimeOfDay(hour: 6, minute: 0),
      );
    });

    testWidgets('a cancelled picker changes and saves nothing', (tester) async {
      final preferences = await _pump(tester);

      await tester.tap(
        find.byKey(DiaryMealSharesEditor.timeKey(MealType.lunch)),
      );
      await tester.pumpAndSettle();
      await cancelOpenTimePicker(tester);

      expect(find.byType(TimePickerDialog), findsNothing);
      expect(_timeOf(tester, MealType.lunch), 'by 1:00 PM');
      expect(preferences.getStringSync(_timesKey), isNull);
    });

    testWidgets('a picked time shows at once and is saved', (tester) async {
      final preferences = await _pump(tester);

      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.lunch),
        const TimeOfDay(hour: 12, minute: 30),
      );

      expect(find.byType(TimePickerDialog), findsNothing);
      expect(_timeOf(tester, MealType.lunch), 'by 12:30 PM');
      expect(_timeOf(tester, MealType.breakfast), 'by 9:00 AM');
      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 6:00 AM');
      expect(preferences.getStringSync(_timesKey), '360,540,750,1140,1260');
    });

    testWidgets('a time picked before the one before pushes that along', (
      tester,
    ) async {
      final preferences = await _pump(tester);

      // Lunch by 8:00 AM, before breakfast's 9:00 AM.
      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.lunch),
        const TimeOfDay(hour: 8, minute: 0),
      );

      expect(_timeOf(tester, MealType.lunch), 'by 8:00 AM');
      expect(_timeOf(tester, MealType.breakfast), 'by 8:00 AM');
      expect(_timeOf(tester, MealType.dinner), 'by 7:00 PM');
      expect(preferences.getStringSync(_timesKey), '360,480,480,1140,1260');
    });

    testWidgets('a time picked after the one after pushes that along', (
      tester,
    ) async {
      final preferences = await _pump(tester);

      // Breakfast by 8:00 PM, past lunch's and dinner's.
      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.breakfast),
        const TimeOfDay(hour: 20, minute: 0),
      );

      expect(_timeOf(tester, MealType.breakfast), 'by 8:00 PM');
      expect(_timeOf(tester, MealType.lunch), 'by 8:00 PM');
      expect(_timeOf(tester, MealType.dinner), 'by 8:00 PM');
      expect(_timeOf(tester, MealType.snack), 'by 9:00 PM');
      expect(preferences.getStringSync(_timesKey), '360,1200,1200,1200,1260');
    });

    testWidgets("a day start after a meal's end pushes the meal along", (
      tester,
    ) async {
      final preferences = await _pump(tester);

      await _pick(
        tester,
        DiaryMealSharesEditor.startKey,
        const TimeOfDay(hour: 10, minute: 0),
      );

      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 10:00 AM');
      expect(_timeOf(tester, MealType.breakfast), 'by 10:00 AM');
      expect(_timeOf(tester, MealType.lunch), 'by 1:00 PM');
      expect(preferences.getStringSync(_timesKey), '600,600,780,1140,1260');
    });

    testWidgets('picking midnight and noon works', (tester) async {
      final preferences = await _pump(tester);

      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.snack),
        const TimeOfDay(hour: 23, minute: 59),
      );
      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.lunch),
        const TimeOfDay(hour: 12, minute: 0),
      );

      expect(_timeOf(tester, MealType.snack), 'by 11:59 PM');
      expect(_timeOf(tester, MealType.lunch), 'by 12:00 PM');
      expect(preferences.getStringSync(_timesKey), '360,540,720,1140,1439');
    });

    testWidgets('times and shares are saved apart', (tester) async {
      final preferences = await _pump(tester);

      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.dinner),
        const TimeOfDay(hour: 18, minute: 0),
      );
      await _drag(tester, 25, 40);

      expect(preferences.getStringSync(_timesKey), '360,540,780,1080,1260');
      expect(preferences.getStringSync(_sharesKey), '40,20,30,10');
      expect(_timeOf(tester, MealType.dinner), 'by 6:00 PM');
      expect(_part(tester, MealType.breakfast), '40 % · 800 kcal');
    });
  });

  group('reset', () {
    testWidgets('goes back to the standard split', (tester) async {
      final preferences = await _pump(tester, savedShares: '0,60,30,10');

      await tester.tap(find.byKey(DiaryMealSharesEditor.resetKey));
      await tester.pumpAndSettle();

      expect(_part(tester, MealType.breakfast), '25 % · 500 kcal');
      expect(preferences.getStringSync(_sharesKey), isNull);
    });

    testWidgets('goes back to the standard times', (tester) async {
      final preferences = await _pump(
        tester,
        savedTimes: '330,480,750,1080,1350',
      );

      await tester.tap(find.byKey(DiaryMealSharesEditor.resetKey));
      await tester.pumpAndSettle();

      expect(_time(tester, DiaryMealSharesEditor.startKey), 'from 6:00 AM');
      expect(_timeOf(tester, MealType.breakfast), 'by 9:00 AM');
      expect(_timeOf(tester, MealType.lunch), 'by 1:00 PM');
      expect(_timeOf(tester, MealType.dinner), 'by 7:00 PM');
      expect(_timeOf(tester, MealType.snack), 'by 9:00 PM');
      expect(preferences.getStringSync(_timesKey), isNull);
    });

    testWidgets('puts back both after the user changed them here', (
      tester,
    ) async {
      final preferences = await _pump(tester);
      await _drag(tester, 25, 40);
      await _pick(
        tester,
        DiaryMealSharesEditor.timeKey(MealType.lunch),
        const TimeOfDay(hour: 8, minute: 0),
      );
      expect(preferences.getStringSync(_sharesKey), '40,20,30,10');
      expect(preferences.getStringSync(_timesKey), '360,480,480,1140,1260');

      await tester.tap(find.byKey(DiaryMealSharesEditor.resetKey));
      await tester.pumpAndSettle();

      expect(_part(tester, MealType.breakfast), '25 % · 500 kcal');
      expect(_part(tester, MealType.lunch), '35 % · 700 kcal');
      expect(_timeOf(tester, MealType.lunch), 'by 1:00 PM');
      expect(_timeOf(tester, MealType.breakfast), 'by 9:00 AM');
      expect(preferences.getStringSync(_sharesKey), isNull);
      expect(preferences.getStringSync(_timesKey), isNull);
    });
  });
}
