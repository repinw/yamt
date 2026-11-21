import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_overdue_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../../helpers/app_font_test_utils.dart';
import '../../../../../calories/support/fake_calories_repositories.dart';
import '../../../../../calories/support/fake_planned_entry_repository.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

// A Saturday; the goal started weeks before, so the calendar opens the
// whole last week.
final _now = DateTime(2026, 10, 31, 12);
final _today = DateTime(2026, 10, 31);
final _tuesday = DateTime(2026, 10, 27);
final _wednesday = DateTime(2026, 10, 28);

/// The grid of a phone 390 px wide, less the page's side padding.
final _metrics = DiaryDashboardMetrics.of(358, TextScaler.noScaling);

/// Pumps the overdue tile of [size] in [mode] on today, with plans on
/// [planDays] that were never eaten.
Future<void> _pump(
  WidgetTester tester,
  DiaryTileSize size,
  String mode, {
  required List<DateTime> planDays,
  bool loadFails = false,
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
  )..loadShouldFail = loadFails;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        plannedEntryRepositoryProvider.overrideWithValue(plans),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width:
                  _metrics.width(size.columns) - 2 * AppDashboard.tilePadding,
              height:
                  _metrics.height(size.rows!) - 2 * AppDashboard.tilePadding,
              child: diaryOverdueTile.builder(
                DiaryTileArgs(day: _today, size: size, mode: mode),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The fit checks of the tiles need real glyph widths, not Ahem's.
  setUpAll(loadAppFonts);

  for (final mode in diaryOverdueTileSpec.modes) {
    testWidgets('2×1 in mode $mode names the tile instead of the days', (
      tester,
    ) async {
      await _pump(
        tester,
        DiaryTileSize.s2x1,
        mode,
        planDays: [_tuesday, _wednesday],
      );

      expect(find.text(_l10n.diaryDashboardOverdueDays(2)), findsNothing);
      expect(find.text(_l10n.diaryDashboardTileOverdue), findsOneWidget);
    });

    testWidgets('4×1 in mode $mode keeps the days with open plans', (
      tester,
    ) async {
      await _pump(
        tester,
        DiaryTileSize.s4x1,
        mode,
        planDays: [_tuesday, _wednesday],
      );

      expect(find.text(_l10n.diaryDashboardOverdueDays(2)), findsOneWidget);
      expect(find.text(_l10n.diaryDashboardTileOverdue), findsNothing);
    });
  }

  testWidgets('4×1 says it of a single day', (tester) async {
    await _pump(
      tester,
      DiaryTileSize.s4x1,
      DiaryTileModes.count,
      planDays: [_wednesday],
    );

    expect(find.text(_l10n.diaryDashboardOverdueDays(1)), findsOneWidget);
  });

  testWidgets('a failed load shows the error, not "no open plans"', (
    tester,
  ) async {
    await _pump(
      tester,
      DiaryTileSize.s4x1,
      DiaryTileModes.count,
      planDays: [_tuesday],
      loadFails: true,
    );

    expect(find.byType(DiaryTileLoadError), findsOneWidget);
    expect(find.text(_l10n.diaryDashboardOverdueNone), findsNothing);
  });
}
