import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

DiaryMealEntry _entry({
  double kcal = 786,
  double? amount,
  int? portions,
  int? ofPortions,
}) {
  return DiaryMealEntry(
    id: 'e1',
    mealType: MealType.lunch,
    name: 'Nudeln',
    totalKcal: kcal,
    totalProtein: 30,
    totalCarbs: 40,
    totalFat: 10,
    consumedAmount: amount,
    bundleConsumedPortions: portions,
    bundleTotalPortions: ofPortions,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required DiaryMealEntry entry,
  double? target,
  Brightness brightness = Brightness.light,
}) async {
  final section = DiaryMealSection(
    mealType: MealType.lunch,
    entries: [entry],
    plannedEntries: const [],
    countsPlans: false,
    totalKcal: entry.totalKcal,
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: DiaryMealGroup(
          section: section,
          targetKcal: target,
          onCopy: () {},
          onTapEntry: (_) {},
          onTapPlan: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The texts of the meal header with their effective colors: the row that
/// holds the meal name.
List<(String, Color?)> _headerLeaves(WidgetTester tester) {
  final header = find
      .ancestor(of: find.text('Mittagessen'), matching: find.byType(Row))
      .first;
  final leaves = <(String, Color?)>[];
  void walk(InlineSpan span, Color? inherited) {
    if (span is! TextSpan) return;
    final color = span.style?.color ?? inherited;
    if (span.text != null) leaves.add((span.text!, color));
    for (final child in span.children ?? const <InlineSpan>[]) {
      walk(child, color);
    }
  }

  for (final element
      in find
          .descendant(of: header, matching: find.byType(RichText))
          .evaluate()) {
    final rich = element.widget as RichText;
    walk(rich.text, null);
  }
  return leaves;
}

bool _isOrange(Color? color) {
  if (color == null) return false;
  final hsl = HSLColor.fromColor(color);
  return hsl.hue >= 15 && hsl.hue <= 45 && hsl.saturation >= 0.6;
}

bool _isPink(Color? color) {
  if (color == null) return false;
  final hsl = HSLColor.fromColor(color);
  return hsl.hue >= 300 && hsl.hue <= 350 && hsl.saturation >= 0.4;
}

void main() {
  testWidgets('R5: the meal header reads name, "786 / 730 kcal", copy', (
    tester,
  ) async {
    await _pump(tester, entry: _entry(), target: 730);

    final name = find.text('Mittagessen');
    final kcal = find.text('786 / 730 kcal', findRichText: true);
    final copy = find.byKey(
      DiaryMealsSectionKeys.mealCopyButton(MealType.lunch),
    );
    expect(name, findsOneWidget);
    expect(kcal, findsOneWidget);
    expect(copy, findsOneWidget);
    expect(tester.getCenter(name).dx, lessThan(tester.getCenter(kcal).dx));
    expect(tester.getCenter(kcal).dx, lessThan(tester.getCenter(copy).dx));
    // The copy button is the rightmost thing of the header.
    expect(
      tester.getTopRight(copy).dx,
      greaterThan(tester.getTopRight(kcal).dx),
    );
  });

  group('R6: only the eaten number turns orange when the meal is over', () {
    // eaten, target, label of the heading, eaten number is orange
    const rows = [
      (786.0, 730.0, '786 / 730 kcal', '786', true),
      (1068.0, 630.0, '1.068 / 630 kcal', '1.068', true),
      (730.0, 730.0, '730 / 730 kcal', '730', false),
      (500.0, 730.0, '500 / 730 kcal', '500', false),
      (0.0, 730.0, '0 / 730 kcal', '0', false),
    ];
    for (final brightness in Brightness.values) {
      for (final (eaten, target, label, number, isOver) in rows) {
        testWidgets('R6 (${brightness.name}): $label has the number '
            '${isOver ? '' : 'not '}in orange', (tester) async {
          await _pump(
            tester,
            entry: _entry(kcal: eaten),
            target: target,
            brightness: brightness,
          );

          expect(find.text(label, findRichText: true), findsOneWidget);
          final leaves = _headerLeaves(tester);
          final eatenLeaf = leaves.singleWhere((leaf) => leaf.$1 == number);
          expect(_isOrange(eatenLeaf.$2), isOver, reason: 'eaten $number');
          for (final leaf in leaves.where((leaf) => leaf.$1 != number)) {
            expect(_isOrange(leaf.$2), isFalse, reason: 'text "${leaf.$1}"');
          }
          for (final leaf in leaves) {
            expect(_isPink(leaf.$2), isFalse, reason: 'text "${leaf.$1}"');
          }
        });
      }
    }

    testWidgets('R6: 786 kcal without a target shows nothing orange', (
      tester,
    ) async {
      await _pump(tester, entry: _entry());

      for (final leaf in _headerLeaves(tester)) {
        expect(_isOrange(leaf.$2), isFalse, reason: 'text "${leaf.$1}"');
        expect(_isPink(leaf.$2), isFalse, reason: 'text "${leaf.$1}"');
      }
    });
  });

  group('R7: entries keep their macros and amount', () {
    testWidgets('R7: "400 g" stands on the right of the entry', (tester) async {
      await _pump(tester, entry: _entry(amount: 400), target: 730);

      final tile = find.byKey(DiaryMealsSectionKeys.entryTile('e1'));
      expect(
        find.descendant(of: tile, matching: find.text('400 g')),
        findsOneWidget,
      );
      expect(
        tester.getCenter(find.text('400 g')).dx,
        greaterThan(tester.getCenter(find.text('Nudeln')).dx),
      );
      final macros = tester
          .widgetList<Text>(
            find.descendant(of: tile, matching: find.byType(Text)),
          )
          .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
          .join(' | ');
      for (final grams in ['30', '40', '10']) {
        expect(macros, contains(grams), reason: 'macro line "$macros"');
      }
    });

    testWidgets('R7: "1/3 Portionen" stands on the right of the entry', (
      tester,
    ) async {
      await _pump(
        tester,
        entry: _entry(portions: 1, ofPortions: 3),
        target: 730,
      );

      expect(find.text('1/3 Portionen'), findsOneWidget);
    });
  });
}
