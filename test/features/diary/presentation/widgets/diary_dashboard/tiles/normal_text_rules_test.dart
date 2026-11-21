// The large-text rules (whole words or nothing, letters, shared number
// size, stacked macro rows, a cap on ledger values) apply only above text
// size 1. At size 1 the tiles keep what they showed in release 3.11.0; the
// expectations here are read off that release (master 78f985109), and
// normal_text_look_test.dart pins every rect. Two cases differ from master on
// purpose, where master overflowed its tile at text size 1: macro bars 4×1 on
// the 288 dp grid, and the budget card on 288 dp on a training day.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import 'large_text_harness.dart';
import 'normal_text_look_support.dart';

const _gridWidths = [288.0, 311.0, 328.0, 379.0];

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

/// Height of [text] as drawn, with the scaling of a shrinking parent.
double _drawnHeight(WidgetTester tester, String text) =>
    tester.getBottomRight(find.text(text)).dy -
    tester.getTopLeft(find.text(text)).dy;

Future<void> _pumpMacros(
  WidgetTester tester,
  DiaryTileSize size,
  String mode,
  double width,
) => pumpInTileSlot(
  tester,
  slot: size,
  gridWidth: width,
  textScale: 1,
  child: DiaryMacrosTileLayout(
    macros: normalTextMacros(_l10n),
    size: size,
    mode: mode,
  ),
);

Future<void> _pumpMeals(
  WidgetTester tester,
  DiaryTileSize size,
  bool bars,
  double width,
) => pumpInTileSlot(
  tester,
  slot: size,
  gridWidth: width,
  textScale: 1,
  child: DiaryMealsTileLayout(
    meals: normalTextMeals(),
    numberFormat: NumberFormat.decimalPattern('de'),
    size: size,
    bars: bars,
  ),
);

void main() {
  setUpAll(loadAppFonts);

  final macros = normalTextMacros(_l10n);
  final names = [for (final macro in macros) macro.label];
  final letters = [for (final macro in macros) macro.letter];

  // How many grams, full names and letters each macros tile shows at text
  // size 1: (grams, full names, letters).
  const shown = {
    (DiaryTileModes.bars, DiaryTileSize.s2x1): (3, 0, 3),
    (DiaryTileModes.bars, DiaryTileSize.s2x2): (3, 3, 0),
    (DiaryTileModes.bars, DiaryTileSize.s4x1): (3, 3, 0),
    (DiaryTileModes.bars, DiaryTileSize.s4x2): (3, 3, 0),
    (DiaryTileModes.rings, DiaryTileSize.s2x1): (0, 0, 3),
    (DiaryTileModes.rings, DiaryTileSize.s2x2): (3, 0, 3),
    (DiaryTileModes.rings, DiaryTileSize.s4x1): (3, 0, 3),
    (DiaryTileModes.rings, DiaryTileSize.s4x2): (3, 0, 3),
    (DiaryTileModes.numbers, DiaryTileSize.s2x1): (3, 0, 3),
    (DiaryTileModes.numbers, DiaryTileSize.s2x2): (3, 0, 3),
    (DiaryTileModes.numbers, DiaryTileSize.s4x1): (3, 3, 0),
    (DiaryTileModes.numbers, DiaryTileSize.s4x2): (3, 3, 0),
  };

  group('macros tile at text size 1', () {
    for (final MapEntry(key: (mode, size), value: (grams, full, short))
        in shown.entries) {
      for (final width in _gridWidths) {
        testWidgets(
          '$mode ${size.name} shows $grams grams, $full names and $short '
          'letters on a grid of ${width.round()} dp',
          (tester) async {
            await _pumpMacros(tester, size, mode, width);

            expect(shownCount(normalTextGrams), grams);
            expect(shownCount(names), full);
            expect(shownCount(letters), short);
          },
        );
      }
    }

    // Where the grams do not fit at their full size, each shrinks on its
    // own at size 1, so that the three differ.
    const individual = [
      (DiaryTileModes.bars, DiaryTileSize.s2x1, [288.0, 311.0, 379.0]),
      (DiaryTileModes.bars, DiaryTileSize.s4x1, [288.0, 311.0, 379.0]),
      (DiaryTileModes.rings, DiaryTileSize.s2x2, [288.0, 311.0, 379.0]),
      (DiaryTileModes.rings, DiaryTileSize.s4x1, [288.0, 311.0, 379.0]),
      (DiaryTileModes.numbers, DiaryTileSize.s2x1, [288.0, 311.0, 379.0]),
      (DiaryTileModes.numbers, DiaryTileSize.s2x2, [288.0, 311.0, 379.0]),
      (DiaryTileModes.numbers, DiaryTileSize.s4x1, [288.0, 311.0, 379.0]),
      (DiaryTileModes.numbers, DiaryTileSize.s4x2, [288.0, 311.0, 379.0]),
    ];
    for (final (mode, size, widths) in individual) {
      for (final width in widths) {
        testWidgets(
          '$mode ${size.name} sizes each grams on its own on a grid of '
          '${width.round()} dp',
          (tester) async {
            await _pumpMacros(tester, size, mode, width);

            final heights = [
              for (final grams in normalTextGrams) _drawnHeight(tester, grams),
            ];
            // The longest text is the smallest, the shortest the largest.
            expect(heights[1], lessThan(heights[0] - 1), reason: '$heights');
            expect(heights[2], greaterThan(heights[1] + 1), reason: '$heights');
          },
        );
      }
    }

    testWidgets('bars 4×1 give each name the width of its own text', (
      tester,
    ) async {
      await _pumpMacros(tester, DiaryTileSize.s4x1, DiaryTileModes.bars, 311);

      final widths = [
        for (final name in names) tester.getSize(find.text(name)).width,
      ];
      expect(widths[0], closeTo(45.81, 0.5), reason: names[0]);
      expect(widths[1], closeTo(59.54, 0.5), reason: names[1]);
      expect(widths[2], closeTo(28.72, 0.5), reason: names[2]);
    });

    // Where each text of the first bar sits in the tile, as in master.
    Rect inTile(WidgetTester tester, String text) => tester
        .getRect(find.text(text))
        .shift(-tester.getTopLeft(find.byKey(largeTextSlotKey)));

    testWidgets('bars 4×1 draw the names and grams of master at their places', (
      tester,
    ) async {
      await _pumpMacros(tester, DiaryTileSize.s4x1, DiaryTileModes.bars, 311);

      final first = inTile(tester, names[0]);
      expect(first.left, closeTo(0, 0.01));
      expect(first.top, closeTo(4.43, 0.01));
      expect(inTile(tester, names[1]).left, closeTo(99, 0.01));
      expect(inTile(tester, names[2]).left, closeTo(198, 0.01));
      final grams = inTile(tester, normalTextGrams[0]);
      expect(grams.left, closeTo(53.81, 0.01));
      expect(grams.top, closeTo(5.05, 0.01));
      expect(grams.width, closeTo(35.19, 0.01));
    });

    testWidgets('bars 4×1 on a 320 dp phone no longer overflow their tile', (
      tester,
    ) async {
      // Master overflowed the 288 dp grid tile by 0.9 dp here. This differs
      // from master on purpose: the row shrinks a little and fits.
      await _pumpMacros(tester, DiaryTileSize.s4x1, DiaryTileModes.bars, 288);

      expect(tester.takeException(), isNull);
      expect(shownCount(names), 3);
      expect(shownCount(normalTextGrams), 3);
    });
  });

  group('meals tile at text size 1', () {
    final mealNames = [
      for (final type in MealType.values) type.localizedName(_l10n),
    ];
    final kcals = ['1.250', '820', '45', '310'];

    for (final width in _gridWidths) {
      for (final (size, bars, nameCount) in [
        (DiaryTileSize.s2x1, false, 0),
        (DiaryTileSize.s2x2, false, 0),
        (DiaryTileSize.s4x1, false, 4),
        (DiaryTileSize.s4x2, false, 4),
        (DiaryTileSize.s2x1, true, 0),
        (DiaryTileSize.s2x2, true, 0),
        (DiaryTileSize.s4x1, true, 0),
        (DiaryTileSize.s4x2, true, 4),
      ]) {
        testWidgets(
          '${bars ? 'bars' : 'list'} ${size.name} shows $nameCount names and '
          'four kcal on a grid of ${width.round()} dp',
          (tester) async {
            await _pumpMeals(tester, size, bars, width);

            expect(shownCount(mealNames), nameCount);
            expect(shownCount(kcals), 4);
          },
        );
      }
    }

    testWidgets('list 4×1 on a 320 dp phone cuts long names with an ellipsis', (
      tester,
    ) async {
      await _pumpMeals(tester, DiaryTileSize.s4x1, false, 288);

      // The whole name is the text; its box is narrower than the text, so
      // it ends in an ellipsis. Master drew the same.
      final lunch = find.text(MealType.lunch.localizedName(_l10n));
      final text = tester.widget<Text>(lunch);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(lunch).width, closeTo(60, 0.01));
      final breakfast = find.text(MealType.breakfast.localizedName(_l10n));
      expect(tester.getSize(breakfast).width, closeTo(58.98, 0.01));
    });

    testWidgets('list 4×1 on a 360 dp screen gives each name its own width', (
      tester,
    ) async {
      await _pumpMeals(tester, DiaryTileSize.s4x1, false, 328);

      for (final (type, width) in [
        (MealType.breakfast, 58.98),
        (MealType.lunch, 70.0),
        (MealType.dinner, 70.0),
        (MealType.snack, 36.58),
      ]) {
        expect(
          tester.getSize(find.text(type.localizedName(_l10n))).width,
          closeTo(width, 0.01),
          reason: type.name,
        );
      }
    });

    testWidgets('list 4×2 shows all four names at the same place as master', (
      tester,
    ) async {
      await _pumpMeals(tester, DiaryTileSize.s4x2, false, 328);

      final lunch = tester
          .getRect(find.text(MealType.lunch.localizedName(_l10n)))
          .shift(-tester.getTopLeft(find.byKey(largeTextSlotKey)));
      expect(lunch.left, closeTo(22, 0.01));
      expect(lunch.top, closeTo(42.75, 0.01));
      expect(lunch.width, closeTo(71.92, 0.01));
    });

    testWidgets('the kcal of a list take one size each on their own', (
      tester,
    ) async {
      await _pumpMeals(tester, DiaryTileSize.s4x1, false, 288);

      final heights = [for (final kcal in kcals) _drawnHeight(tester, kcal)];
      // 1.250 is wider than the others and shrinks more.
      expect(heights[0], lessThan(heights[2] - 1), reason: '$heights');
    });
  });

  group('budget macro column at text size 1', () {
    Future<void> pump(WidgetTester tester, double width) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: DiaryBudgetMacroColumn(
                  data: normalTextCardData(),
                  showDetails: false,
                  showEaten: false,
                  numberFormat: NumberFormat.decimalPattern('de'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final width in [130.0, 160.0, 300.0]) {
      testWidgets('keeps the grams beside their names at ${width.round()} dp', (
        tester,
      ) async {
        await pump(tester, width);

        expect(tester.takeException(), isNull);
        final valueWidths = <double>[];
        for (final kind in DiaryBudgetMacroKind.values) {
          final name = tester.getRect(
            find.text(diaryBudgetMacroLabel(_l10n, kind)),
          );
          final value = tester.getRect(
            find.byKey(DiaryBudgetCardKeys.macroValue(kind)),
          );
          // One line: the grams start where the name ends, at the right
          // edge, and are no taller than the name's line plus its gap.
          expect(value.left, closeTo(name.right, 0.01), reason: kind.name);
          expect(value.right, closeTo(width, 0.01), reason: kind.name);
          expect(value.top, lessThan(name.bottom), reason: kind.name);
          valueWidths.add(value.width);
        }
        // Each grams value has the width of its own text.
        expect(valueWidths[0], closeTo(83.77, 0.01));
        expect(valueWidths[1], closeTo(49.08, 0.01));
        expect(valueWidths[2], closeTo(34.45, 0.01));
      });
    }
  });
}
