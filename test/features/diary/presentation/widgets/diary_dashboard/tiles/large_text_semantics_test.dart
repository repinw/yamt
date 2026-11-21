// What a tile drops at large text, or draws as a letter, a screen reader
// still says in full; and the Bold Text setting makes tiles drop what no
// longer fits whole, as larger text does.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import 'large_text_harness.dart';
import 'normal_text_look_support.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

Future<void> _pumpMacros(
  WidgetTester tester,
  DiaryTileSize size,
  String mode,
  double width, {
  double textScale = largeTextScale,
  bool boldText = false,
}) => pumpInTileSlot(
  tester,
  slot: size,
  gridWidth: width,
  textScale: textScale,
  boldText: boldText,
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
  double width, {
  double textScale = largeTextScale,
  bool boldText = false,
}) => pumpInTileSlot(
  tester,
  slot: size,
  gridWidth: width,
  textScale: textScale,
  boldText: boldText,
  child: DiaryMealsTileLayout(
    meals: normalTextMeals(),
    numberFormat: NumberFormat.decimalPattern('de'),
    size: size,
    bars: bars,
  ),
);

final List<String> _mealNames = [
  for (final type in MealType.values) type.localizedName(_l10n),
];

void main() {
  setUpAll(loadAppFonts);

  final macros = normalTextMacros(_l10n);
  final fullNames = [for (final macro in macros) macro.label];
  final letters = [for (final macro in macros) macro.letter];
  final total = _l10n.diaryMacroEatenOfTarget('88', '128');

  group('macros tile for a screen reader at text size 2', () {
    testWidgets('bars 2×1 read the grams that they drop', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpMacros(tester, DiaryTileSize.s2x1, DiaryTileModes.bars, 288);

      expect(shownCount(normalTextGrams), 0);
      for (final grams in normalTextGrams) {
        expect(find.bySemanticsLabel(grams), findsOneWidget, reason: grams);
      }
      semantics.dispose();
    });

    for (final (mode, size) in [
      (DiaryTileModes.bars, DiaryTileSize.s2x1),
      (DiaryTileModes.rings, DiaryTileSize.s2x1),
      (DiaryTileModes.numbers, DiaryTileSize.s2x2),
    ]) {
      testWidgets('$mode ${size.name} read the full names behind the '
          'letters', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpMacros(tester, size, mode, 288);

        expect(shownCount(letters), 3);
        expect(shownCount(fullNames), 0);
        for (final name in fullNames) {
          expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
        }
        semantics.dispose();
      });
    }

    testWidgets('names that show in full are read once, as themselves', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMacros(
        tester,
        DiaryTileSize.s4x2,
        DiaryTileModes.numbers,
        379,
        textScale: 1,
      );

      expect(shownCount(fullNames), 3);
      for (final name in fullNames) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      semantics.dispose();
    });

    testWidgets('numbers 4×2 read "eaten of target" where the line drops it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMacros(
        tester,
        DiaryTileSize.s4x2,
        DiaryTileModes.numbers,
        288,
      );

      // The line is gone from the page; a screen reader reads it for each
      // of the three macros.
      expect(find.text(total), findsNothing);
      expect(find.bySemanticsLabel(total), findsNWidgets(3));
      semantics.dispose();
    });

    testWidgets('numbers 4×2 show "eaten of target" once at normal text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMacros(
        tester,
        DiaryTileSize.s4x2,
        DiaryTileModes.numbers,
        379,
        textScale: 1,
      );

      expect(find.text(total), findsNWidgets(3));
      expect(find.bySemanticsLabel(total), findsNWidgets(3));
      semantics.dispose();
    });
  });

  group('meals tile for a screen reader', () {
    testWidgets('list 4×1 at text size 2 reads the names its icons carry', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMeals(tester, DiaryTileSize.s4x1, false, 288);

      expect(shownCount(_mealNames), 0);
      for (final name in _mealNames) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      semantics.dispose();
    });

    testWidgets('list 2×2 never shows names, so its icons carry them', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMeals(tester, DiaryTileSize.s2x2, false, 379, textScale: 1);

      expect(shownCount(_mealNames), 0);
      for (final name in _mealNames) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      semantics.dispose();
    });

    testWidgets('names that show are read once, by the text and not the icon', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpMeals(tester, DiaryTileSize.s4x2, false, 379, textScale: 1);

      expect(shownCount(_mealNames), 4);
      for (final name in _mealNames) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      semantics.dispose();
    });
  });

  group('Bold Text makes tiles drop what no longer fits whole', () {
    // Grids where all four names fit whole in the 4×1 list without Bold
    // Text, and no longer fit with it.
    for (final (scale, width) in [(1.15, 388.0), (1.3, 428.0), (1.5, 488.0)]) {
      testWidgets('list 4×1 drops all four names with bold text at text size '
          '$scale on a grid of ${width.round()} dp', (tester) async {
        await _pumpMeals(
          tester,
          DiaryTileSize.s4x1,
          false,
          width,
          textScale: scale,
        );
        expect(shownCount(_mealNames), 4, reason: 'regular text');

        await _pumpMeals(
          tester,
          DiaryTileSize.s4x1,
          false,
          width,
          textScale: scale,
          boldText: true,
        );

        expect(tester.takeException(), isNull);
        expect(shownCount(_mealNames), 0, reason: 'bold text');
      });
    }

    testWidgets('a caption that shows is whole, not cut, at 1.5 with bold '
        'text', (tester) async {
      var dropped = 0;
      var shown = 0;
      for (var width = 288.0; width <= 488; width += 20) {
        await _pumpMacros(
          tester,
          DiaryTileSize.s4x2,
          DiaryTileModes.numbers,
          width,
          textScale: 1.5,
          boldText: true,
        );

        expect(tester.takeException(), isNull, reason: '$width');
        final texts = find.text(total).evaluate().length;
        if (texts == 0) {
          dropped++;
          continue;
        }
        shown++;
        for (var index = 0; index < texts; index++) {
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(total).at(index))
                .didExceedMaxLines,
            isFalse,
            reason: '$width',
          );
        }
      }
      expect(dropped, greaterThan(0));
      expect(shown, greaterThan(0));
    });

    testWidgets('the macros keep all names or all letters at 1.5 with bold '
        'text', (tester) async {
      for (final mode in diaryMacrosTileSpec.modes) {
        for (final size in diaryMacrosTileSpec.sizes) {
          for (final width in largeTextGridWidths) {
            await _pumpMacros(
              tester,
              size,
              mode,
              width,
              textScale: 1.5,
              boldText: true,
            );

            final reason = '$mode ${size.name} ${width.round()} dp';
            expect(tester.takeException(), isNull, reason: reason);
            final full = shownCount(fullNames);
            final short = shownCount(letters);
            expect(
              (full == 3 && short == 0) || (full == 0 && short == 3),
              isTrue,
              reason: '$reason full: $full, letters: $short',
            );
          }
        }
      }
    });
  });
}
