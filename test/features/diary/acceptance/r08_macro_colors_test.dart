import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<ThemeData> _pump(
  WidgetTester tester, {
  required bool allMacrosColored,
  required Brightness brightness,
}) async {
  const entry = DiaryMealEntry(
    id: 'e1',
    mealType: MealType.lunch,
    name: 'Nudeln',
    totalKcal: 786,
    totalProtein: 31,
    totalCarbs: 42,
    totalFat: 13,
  );
  final base = brightness == Brightness.dark
      ? AppTheme.dark()
      : AppTheme.light();
  final theme = base.withAllMacrosColored(value: allMacrosColored);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      home: Scaffold(
        body: DiaryMealGroup(
          section: DiaryMealSection(
            mealType: MealType.lunch,
            entries: const [entry],
            plannedEntries: const [],
            countsPlans: false,
            totalKcal: 786,
          ),
          targetKcal: 900,
          onCopy: () {},
          onTapEntry: (_) {},
          onTapPlan: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  return theme;
}

/// The text leaves of the entry tile with their colors and backgrounds.
List<(String, Color?, bool)> _leaves(WidgetTester tester) {
  final tile = find.byKey(DiaryMealsSectionKeys.entryTile('e1'));
  final leaves = <(String, Color?, bool)>[];
  void walk(InlineSpan span, Color? inherited) {
    if (span is! TextSpan) return;
    final color = span.style?.color ?? inherited;
    final hasBackground =
        span.style?.background != null || span.style?.backgroundColor != null;
    if (span.text != null) leaves.add((span.text!, color, hasBackground));
    for (final child in span.children ?? const <InlineSpan>[]) {
      walk(child, color);
    }
  }

  for (final element
      in find
          .descendant(of: tile, matching: find.byType(RichText))
          .evaluate()) {
    walk((element.widget as RichText).text, null);
  }
  return leaves;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final setting in [true, false]) {
      testWidgets(
        'R8 (${brightness.name}): macro numbers are red, blue, yellow with '
        '"Makros immer bunt" ${setting ? 'on' : 'off'}',
        (tester) async {
          final theme = await _pump(
            tester,
            allMacrosColored: setting,
            brightness: brightness,
          );
          final colors = theme.extension<MetricAccentColors>()!;
          final leaves = _leaves(tester);

          Color? colorOf(String number) {
            final matches = leaves.where(
              (leaf) => RegExp('(^|\\D)$number(\\D|\$)').hasMatch(leaf.$1),
            );
            expect(matches, hasLength(1), reason: 'number $number in $leaves');
            return matches.single.$2;
          }

          expect(colorOf('31'), colors.protein, reason: 'protein');
          expect(colorOf('42'), colors.carbs, reason: 'carbs');
          expect(colorOf('13'), colors.fat, reason: 'fat');
          // Only the numbers carry a macro colour; no backgrounds anywhere.
          final macroColors = {colors.protein, colors.carbs, colors.fat};
          for (final leaf in leaves) {
            expect(leaf.$3, isFalse, reason: 'background on "${leaf.$1}"');
            if (!RegExp('^(31|42|13)').hasMatch(leaf.$1.trim())) {
              expect(
                macroColors.contains(leaf.$2),
                isFalse,
                reason: 'text "${leaf.$1}" must not be macro-coloured',
              );
            }
          }
        },
      );
    }
  }
}
