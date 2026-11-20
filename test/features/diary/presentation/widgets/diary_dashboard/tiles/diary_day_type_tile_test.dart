import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_day_type_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../calories/support/fake_calories_repositories.dart';

final _day = DateTime(2026, 11, 20);

/// The grid of a narrow phone 320 px wide, less the page's side padding.
const _gridWidth = 288.0;

/// Pumps the day type tile of [size] in [mode] at text size [textScale],
/// in a slot of [slot] (by default [size]).
Future<void> _pump(
  WidgetTester tester,
  DiaryTileSize size,
  String mode, {
  required DiaryDayType type,
  required double textScale,
  DiaryTileSize? slot,
}) async {
  final slotSize = slot ?? size;
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
  final textScaler = TextScaler.linear(textScale);
  final metrics = DiaryDashboardMetrics.of(_gridWidth, textScaler);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(
          () => _day.add(const Duration(hours: 12)),
        ),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width:
                    metrics.width(slotSize.columns) -
                    2 * AppDashboard.tilePadding,
                height:
                    metrics.height(slotSize.rows!) -
                    2 * AppDashboard.tilePadding,
                child: diaryDayTypeTile.builder(
                  DiaryTileArgs(day: _day, size: size, mode: mode),
                ),
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
  for (final size in diaryDayTypeTileSpec.sizes) {
    for (final mode in diaryDayTypeTileSpec.modes) {
      for (final type in DiaryDayType.values) {
        testWidgets(
          '${size.name} in mode $mode fits a narrow phone at text size 2 '
          'on a ${type.name} day',
          (tester) async {
            await _pump(tester, size, mode, type: type, textScale: 2);

            expect(tester.takeException(), isNull);

            expect(find.byType(DiaryTileNoValue), findsNothing);
          },
        );
      }
    }
  }

  // A resized tile slides to its new size, so the 2×1 content first draws
  // in the slot of a 1×1 tile.
  for (final mode in diaryDayTypeTileSpec.modes) {
    testWidgets('2×1 in mode $mode fits while it grows from 1×1 at text '
        'size 2', (tester) async {
      await _pump(
        tester,
        DiaryTileSize.s2x1,
        mode,
        type: DiaryDayType.training,
        textScale: 2,
        slot: DiaryTileSize.s1x1,
      );

      expect(tester.takeException(), isNull);

      expect(find.byType(DiaryTileNoValue), findsNothing);
    });
  }
}
