import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/models/diary_meal_kcal.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import 'large_text_harness.dart';

const FoodLabelColors _colors = FoodLabelColors.light;

/// Grams of three different lengths, so that a size that follows each text
/// alone would differ.
const _grams = ['128 g', '1.234 g', '40 g'];

List<DiaryMacroTileView> _macros(AppLocalizations l10n) {
  DiaryMacroTileView macro(
    DiaryBudgetMacroKind kind,
    String letter,
    String value,
  ) => (
    letter: letter,
    label: diaryBudgetMacroLabel(l10n, kind),
    value: value,
    total: l10n.diaryMacroEatenOfTarget('88', '128'),
    labelColor: _colors.ink,
    valueColor: _colors.ink,
    eaten: 88,
    planned: 0,
    target: 128,
    scale: 128,
    eatenColor: _colors.accent,
  );
  return [
    macro(
      DiaryBudgetMacroKind.protein,
      l10n.diaryDashboardMacroProteinShort,
      _grams[0],
    ),
    macro(
      DiaryBudgetMacroKind.carbs,
      l10n.diaryDashboardMacroCarbsShort,
      _grams[1],
    ),
    macro(
      DiaryBudgetMacroKind.fat,
      l10n.diaryDashboardMacroFatShort,
      _grams[2],
    ),
  ];
}

List<DiaryMealKcal> _meals() => [
  const DiaryMealKcal(mealType: MealType.breakfast, eaten: 1250, planned: 0),
  const DiaryMealKcal(mealType: MealType.lunch, eaten: 820, planned: 0),
  const DiaryMealKcal(mealType: MealType.dinner, eaten: 45, planned: 0),
  const DiaryMealKcal(mealType: MealType.snack, eaten: 310, planned: 0),
];

double _height(WidgetTester tester, String text) =>
    tester.getRect(find.text(text)).height;

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['de', 'en']) {
    final l10n = lookupAppLocalizations(Locale(locale));
    final macros = _macros(l10n);
    final fullNames = [for (final macro in macros) macro.label];
    final letters = [for (final macro in macros) macro.letter];

    group('macros tile at text size 2 in $locale', () {
      for (final mode in diaryMacrosTileSpec.modes) {
        for (final size in diaryMacrosTileSpec.sizes) {
          for (final slot in [
            size,
            ...growSlots(size, diaryMacrosTileSpec.sizes),
          ]) {
            for (final width in largeTextGridWidths) {
              final grows = slot == size
                  ? ''
                  : ' while it grows from ${slot.name}';
              testWidgets(
                '$mode ${size.name} on a grid of ${width.round()} dp$grows',
                (tester) async {
                  await pumpInTileSlot(
                    tester,
                    locale: locale,
                    slot: slot,
                    gridWidth: width,
                    child: DiaryMacrosTileLayout(
                      macros: macros,
                      size: size,
                      mode: mode,
                    ),
                  );

                  expect(tester.takeException(), isNull);

                  // The grams that show take one size.
                  final shown = [
                    for (final grams in _grams)
                      if (find.text(grams).evaluate().isNotEmpty) grams,
                  ];
                  for (final grams in shown) {
                    expect(
                      _height(tester, grams),
                      closeTo(_height(tester, shown.first), 0.01),
                      reason: 'grams $grams',
                    );
                  }

                  // All names in full, or all of them as letters.
                  final full = shownCount(fullNames);
                  final short = shownCount(letters);
                  expect(
                    (full == 3 && short == 0) || (full == 0 && short == 3),
                    isTrue,
                    reason: 'full: $full, letters: $short',
                  );
                },
              );
            }
          }
        }
      }

      for (final width in largeTextGridWidths) {
        testWidgets('bars 2×1 show no grams on a grid of ${width.round()} dp', (
          tester,
        ) async {
          await pumpInTileSlot(
            tester,
            locale: locale,
            slot: DiaryTileSize.s2x1,
            gridWidth: width,
            child: DiaryMacrosTileLayout(
              macros: macros,
              size: DiaryTileSize.s2x1,
              mode: DiaryTileModes.bars,
            ),
          );

          expect(shownCount(_grams), 0);
          expect(shownCount(letters), 3);
        });

        testWidgets(
          'rings 4×1 show no grams on a grid of ${width.round()} dp',
          (tester) async {
            await pumpInTileSlot(
              tester,
              locale: locale,
              slot: DiaryTileSize.s4x1,
              gridWidth: width,
              child: DiaryMacrosTileLayout(
                macros: macros,
                size: DiaryTileSize.s4x1,
                mode: DiaryTileModes.rings,
              ),
            );

            expect(shownCount(_grams), 0);
            expect(shownCount(letters), 3);
          },
        );
      }
    });

    // Without large text the same tiles show everything; this keeps the
    // finders above honest.
    testWidgets('macros numbers 4×1 show full names and all grams at normal '
        'text in $locale', (tester) async {
      await pumpInTileSlot(
        tester,
        locale: locale,
        slot: DiaryTileSize.s4x1,
        gridWidth: 379,
        textScale: 1,
        child: DiaryMacrosTileLayout(
          macros: macros,
          size: DiaryTileSize.s4x1,
          mode: DiaryTileModes.numbers,
        ),
      );

      expect(shownCount(fullNames), 3);
      expect(shownCount(_grams), 3);
    });

    testWidgets('meals list 4×2 shows all four names at normal text in '
        '$locale', (tester) async {
      await pumpInTileSlot(
        tester,
        locale: locale,
        slot: DiaryTileSize.s4x2,
        gridWidth: 379,
        textScale: 1,
        child: DiaryMealsTileLayout(
          meals: _meals(),
          numberFormat: NumberFormat.decimalPattern(locale),
          size: DiaryTileSize.s4x2,
          bars: false,
        ),
      );

      expect(
        shownCount([
          for (final type in MealType.values) type.localizedName(l10n),
        ]),
        4,
      );
    });

    group('meals tile at text size 2 in $locale', () {
      final names = [
        for (final type in MealType.values) type.localizedName(l10n),
      ];
      final kcals = [
        for (final meal in _meals())
          NumberFormat.decimalPattern(locale).format(meal.total.round()),
      ];

      for (final bars in [true, false]) {
        for (final size in diaryMealsTileSpec.sizes) {
          for (final slot in [
            size,
            ...growSlots(size, diaryMealsTileSpec.sizes),
          ]) {
            for (final width in largeTextGridWidths) {
              final grows = slot == size
                  ? ''
                  : ' while it grows from ${slot.name}';
              testWidgets('${bars ? 'bars' : 'list'} ${size.name} on a grid of '
                  '${width.round()} dp$grows', (tester) async {
                await pumpInTileSlot(
                  tester,
                  locale: locale,
                  slot: slot,
                  gridWidth: width,
                  child: DiaryMealsTileLayout(
                    meals: _meals(),
                    numberFormat: NumberFormat.decimalPattern(locale),
                    size: size,
                    bars: bars,
                  ),
                );

                expect(tester.takeException(), isNull);

                // The four kcal show, at one size.
                for (final kcal in kcals) {
                  expect(find.text(kcal), findsOneWidget, reason: kcal);
                  expect(
                    _height(tester, kcal),
                    closeTo(_height(tester, kcals.first), 0.01),
                    reason: 'kcal $kcal',
                  );
                }

                // The four meal names, or none.
                final named = shownCount(names);
                expect(
                  named == 0 || named == 4,
                  isTrue,
                  reason: 'names: $named',
                );
              });
            }
          }
        }
      }
    });
  }
}
