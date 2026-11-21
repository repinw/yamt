import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_overdue_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import '../../../../../calories/support/fake_calories_repositories.dart';
import '../../../../../calories/support/fake_planned_entry_repository.dart';
import 'large_text_harness.dart';

// A Saturday; the goal started weeks before, so the calendar opens the
// whole last week.
final _now = DateTime(2026, 10, 31, 12);
final _today = DateTime(2026, 10, 31);

/// Five past days with a plan that was never eaten.
final List<DateTime> _planDays = [
  for (var day = 25; day <= 29; day++) DateTime(2026, 10, day),
];

Future<void> _pump(
  WidgetTester tester,
  DiaryTileSize size,
  String mode, {
  required List<DateTime> planDays,
  required double gridWidth,
  required DiaryTileSize slot,
  String locale = 'de',
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: const CalorieGoalSettings.empty().copyWith(
      goalHistory: [
        CalorieGoalHistoryEntry(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 9),
          changedAt: DateTime(2026, 9),
        ),
      ],
    ),
  );
  addTearDown(settings.dispose);
  final plans = FakePlannedEntryRepository(
    plans: [
      for (final day in planDays)
        buildQuickCalorieEntry(
          id: '$day',
          userId: 'user-1',
          name: 'Pasta',
          mealType: MealType.dinner,
          loggedAt: day.add(const Duration(hours: 19)),
          now: day,
          kcal: 700,
        ),
    ],
  );
  await pumpInTileSlot(
    tester,
    locale: locale,
    slot: slot,
    gridWidth: gridWidth,
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      calorieSettingsRepositoryProvider.overrideWithValue(settings),
      plannedEntryRepositoryProvider.overrideWithValue(plans),
    ],
    child: diaryOverdueTile.builder(
      DiaryTileArgs(day: _today, size: size, mode: mode),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['de', 'en']) {
    for (final mode in diaryOverdueTileSpec.modes) {
      for (final size in diaryOverdueTileSpec.sizes) {
        for (final slot in [
          size,
          ...growSlots(size, diaryOverdueTileSpec.sizes),
        ]) {
          for (final width in largeTextGridWidths) {
            final grows = slot == size
                ? ''
                : ' while it grows from ${slot.name}';

            testWidgets(
              '$mode ${size.name} keeps its icon at text size 2 on a grid of '
              '${width.round()} dp in $locale$grows',
              (tester) async {
                await _pump(
                  tester,
                  size,
                  mode,
                  planDays: _planDays,
                  gridWidth: width,
                  slot: slot,
                  locale: locale,
                );

                expect(tester.takeException(), isNull);
                expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
              },
            );

            testWidgets(
              '$mode ${size.name} without open plans keeps its icon at text '
              'size 2 on a grid of ${width.round()} dp in $locale$grows',
              (tester) async {
                await _pump(
                  tester,
                  size,
                  mode,
                  planDays: const [],
                  gridWidth: width,
                  slot: slot,
                  locale: locale,
                );

                expect(tester.takeException(), isNull);
                expect(
                  find.byIcon(Icons.check_circle_outline_rounded),
                  findsOneWidget,
                );
              },
            );
          }
        }
      }
    }
  }

  group('a screen reader reads the caption of a tile', () {
    // Where the caption drops out of a narrow tile, its icon says it.
    final l10n = lookupAppLocalizations(const Locale('de'));
    for (final (size, withPlans, caption) in [
      (DiaryTileSize.s2x1, true, l10n.diaryDashboardTileOverdue),
      (DiaryTileSize.s4x1, true, l10n.diaryDashboardOverdueDays(5)),
      (DiaryTileSize.s2x1, false, l10n.diaryDashboardOverdueNone),
      (DiaryTileSize.s4x1, false, l10n.diaryDashboardOverdueNone),
    ]) {
      testWidgets('${size.name} ${withPlans ? 'with' : 'without'} open plans '
          'reads "$caption" once at text size 2', (tester) async {
        final semantics = tester.ensureSemantics();
        for (final width in largeTextGridWidths) {
          await _pump(
            tester,
            size,
            DiaryTileModes.count,
            planDays: withPlans ? _planDays : const [],
            gridWidth: width,
            slot: size,
          );

          expect(tester.takeException(), isNull, reason: '$width');
          // On the page as a text, or, where it dropped out, in its icon; the
          // tile's tap merges it with the number.
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(caption))),
            findsOneWidget,
            reason: '${width.round()} dp',
          );
        }
        semantics.dispose();
      });
    }

    testWidgets('2×1 drops the caption of open plans on the narrowest grid '
        'and its icon reads it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        DiaryTileSize.s2x1,
        DiaryTileModes.count,
        planDays: _planDays,
        gridWidth: 288,
        slot: DiaryTileSize.s2x1,
      );

      expect(find.text(l10n.diaryDashboardTileOverdue), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.diaryDashboardTileOverdue)),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
