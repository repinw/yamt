import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

DiaryMealEntry _entry(String name, double kcal) => DiaryMealEntry(
  id: name,
  mealType: MealType.lunch,
  name: name,
  totalKcal: kcal,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
);

DiaryMealSection _lunch(
  List<DiaryMealEntry> entries, {
  List<DiaryMealEntry> plans = const [],
}) => DiaryMealSection(
  mealType: MealType.lunch,
  entries: entries,
  plannedEntries: plans,
  countsPlans: false,
  totalKcal: entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal),
);

Future<void> _pump(
  WidgetTester tester,
  DiaryMealSection section, {
  double? targetKcal,
  bool countsOpenPlans = false,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DiaryMealGroup(
              section: section,
              onTapEntry: (_) {},
              onTapPlan: (_) {},
              countsOpenPlans: countsOpenPlans,
              targetKcal: targetKcal,
            ),
          ),
        ),
      ),
    ),
  );
}

final Finder _target = find.byKey(
  DiaryMealsSectionKeys.mealKcalOfTarget(MealType.lunch),
);

String? _targetText(WidgetTester tester) =>
    _target.evaluate().isEmpty ? null : tester.widget<Text>(_target).data;

void main() {
  group('with a target', () {
    testWidgets('the heading shows the counted kcal against the target, '
        'in place of the plain total', (tester) async {
      await _pump(
        tester,
        _lunch([_entry('Rice', 400), _entry('Chicken', 250)]),
        targetKcal: 700,
      );

      expect(_targetText(tester), '650 / 700 kcal');
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('650 kcal'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a meal of one food shows it too, though its heading would '
        'repeat no total', (tester) async {
      await _pump(tester, _lunch([_entry('Rice', 400)]), targetKcal: 700);

      expect(_targetText(tester), '400 / 700 kcal');
    });

    testWidgets('a meal that only has plans shows 0 against the target', (
      tester,
    ) async {
      await _pump(
        tester,
        _lunch(const [], plans: [_entry('Pasta', 300)]),
        targetKcal: 700,
      );

      expect(_targetText(tester), '0 / 700 kcal');
    });

    testWidgets('rounds both to whole kcal', (tester) async {
      await _pump(tester, _lunch([_entry('Rice', 333.4)]), targetKcal: 666.67);

      expect(_targetText(tester), '333 / 667 kcal');
    });

    testWidgets("counts the open plans in only when today's head does", (
      tester,
    ) async {
      final section = _lunch(
        [_entry('Rice', 400)],
        plans: [_entry('Fish', 250)],
      );

      await _pump(tester, section, targetKcal: 700);
      expect(_targetText(tester), '400 / 700 kcal');

      await _pump(tester, section, targetKcal: 700, countsOpenPlans: true);
      expect(_targetText(tester), '650 / 700 kcal');
    });

    testWidgets('writes the numbers the way the language does', (tester) async {
      await _pump(
        tester,
        _lunch([_entry('Reis', 650), _entry('Hähnchen', 250)]),
        targetKcal: 1250,
        locale: const Locale('de'),
      );

      expect(_targetText(tester), '900 / 1.250 kcal');
    });

    testWidgets('the same in English', (tester) async {
      await _pump(
        tester,
        _lunch([_entry('Rice', 650), _entry('Chicken', 250)]),
        targetKcal: 1250,
      );

      expect(_targetText(tester), '900 / 1,250 kcal');
    });
  });

  group('without a target', () {
    testWidgets('a meal of several foods shows the plain total', (
      tester,
    ) async {
      await _pump(
        tester,
        _lunch([_entry('Rice', 400), _entry('Chicken', 250)]),
      );

      expect(find.text('650 kcal'), findsOneWidget);
      expect(_target, findsNothing);
    });

    testWidgets('a meal of one food repeats no total in its heading', (
      tester,
    ) async {
      await _pump(tester, _lunch([_entry('Rice', 400)]));

      // Only the row of the food shows its kcal.
      expect(find.text('400 kcal'), findsOneWidget);
      expect(_target, findsNothing);
    });
  });
}
