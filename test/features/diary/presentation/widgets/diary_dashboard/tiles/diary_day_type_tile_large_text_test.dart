import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_day_type_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import '../../../../../calories/support/fake_calories_repositories.dart';
import 'large_text_harness.dart';

final _day = DateTime(2026, 11, 20);

Future<void> _pump(
  WidgetTester tester, {
  required DiaryDayType type,
  required String locale,
  required double gridWidth,
  required DiaryTileSize slot,
  DiaryTileSize size = DiaryTileSize.s2x1,
  double textScale = largeTextScale,
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 9),
      trainingWeekdays: [if (type == DiaryDayType.training) _day.weekday],
      pauseDayKeys: [if (type == DiaryDayType.pause) localDayKey(_day)],
    ),
  );
  addTearDown(settings.dispose);
  await pumpInTileSlot(
    tester,
    locale: locale,
    slot: slot,
    gridWidth: gridWidth,
    textScale: textScale,
    overrides: [
      clockProvider.overrideWithValue(
        () => _day.add(const Duration(hours: 12)),
      ),
      calorieSettingsRepositoryProvider.overrideWithValue(settings),
    ],
    child: diaryDayTypeTile.builder(
      DiaryTileArgs(day: _day, size: size, mode: DiaryTileModes.icon),
    ),
  );
}

/// Distinct line tops of the characters [start] to [end] of [paragraph].
int _linesOf(RenderParagraph paragraph, int start, int end) => paragraph
    .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
    .map((box) => box.top.round())
    .toSet()
    .length;

/// Lines the paragraph takes.
int _lineCount(RenderParagraph paragraph) =>
    _linesOf(paragraph, 0, paragraph.text.toPlainText().length);

/// Whether every word of the paragraph sits whole on one line.
bool _noBrokenWord(RenderParagraph paragraph) {
  var start = 0;
  for (final word in paragraph.text.toPlainText().split(' ')) {
    final end = start + word.length;
    if (_linesOf(paragraph, start, end) > 1) return false;
    start = end + 1;
  }
  return true;
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['de', 'en']) {
    final l10n = lookupAppLocalizations(Locale(locale));

    for (final (scale, width) in [
      for (final scale in [1.5, largeTextScale])
        for (final width in largeTextGridWidths) (scale, width),
    ]) {
      // 2×1 at its own size, and while it grows from 1×1.
      for (final slot in [DiaryTileSize.s2x1, DiaryTileSize.s1x1]) {
        testWidgets(
          'icon 2×1 shows its name whole or only the emoji at text size '
          '$scale on a grid of ${width.round()} dp in $locale'
          '${slot == DiaryTileSize.s1x1 ? ' while it grows from 1×1' : ''}',
          (tester) async {
            final semantics = tester.ensureSemantics();
            for (final type in DiaryDayType.values) {
              await _pump(
                tester,
                type: type,
                locale: locale,
                gridWidth: width,
                slot: slot,
                textScale: scale,
              );
              final name = diaryDayTypeLabel(type, l10n);
              final reason = '${type.name} "$name"';

              expect(tester.takeException(), isNull, reason: reason);

              final nameText = find.text(name);
              if (nameText.evaluate().isEmpty) {
                // Only the emoji, which a screen reader still names.
                expect(
                  find.bySemanticsLabel(name),
                  findsOneWidget,
                  reason: reason,
                );
                continue;
              }
              final paragraph = tester.renderObject<RenderParagraph>(nameText);
              expect(
                _lineCount(paragraph),
                lessThanOrEqualTo(2),
                reason: reason,
              );
              expect(_noBrokenWord(paragraph), isTrue, reason: reason);
              final slotRect = tester.getRect(find.byKey(largeTextSlotKey));
              final rect = tester.getRect(nameText);
              expect(rect.bottom, lessThanOrEqualTo(slotRect.bottom + 0.01));
              expect(rect.right, lessThanOrEqualTo(slotRect.right + 0.01));
            }
            semantics.dispose();
          },
        );
      }
    }
  }

  testWidgets('icon 2×1 at normal text shows the name beside the emoji', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('de'));
    await _pump(
      tester,
      type: DiaryDayType.training,
      locale: 'de',
      gridWidth: 379,
      slot: DiaryTileSize.s2x1,
      textScale: 1,
    );

    expect(
      find.text(diaryDayTypeLabel(DiaryDayType.training, l10n)),
      findsOneWidget,
    );
  });
}
