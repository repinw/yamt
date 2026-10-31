import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_card_data_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_kcal_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_meals_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_ring.dart';
import 'package:yamt/l10n/app_localizations.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

final _day = DateTime(2026, 4, 27);

/// The grid of a phone 390 px wide, less the page's side padding.
final _metrics = DiaryDashboardMetrics.of(358, TextScaler.noScaling);

const _dailyMetrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 800,
  eatenKcal: 800,
  realDayLeftKcal: 1200,
  dayLeftKcal: 1200,
  targetKcal: 2000,
);

/// 2300 of 2000 kcal eaten.
const _overMetrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 2300,
  eatenKcal: 2300,
  realDayLeftKcal: -300,
  dayLeftKcal: -300,
  targetKcal: 2000,
);

/// Fat has the lowest share of its target (20 of 60 g).
DiaryBudgetCardData _data({
  double? paceKcal,
  bool isPauseDay = false,
  DiaryDayStatus status = DiaryDayStatus.today,
  DiaryDailyBalanceMetrics metrics = _dailyMetrics,
  bool overIsMiss = true,
}) => DiaryBudgetCardData(
  day: _day,
  status: status,
  metrics: metrics,
  isPauseDay: isPauseDay,
  overIsMiss: overIsMiss,
  paceKcal: paceKcal,
  macros: const [
    (kind: DiaryBudgetMacroKind.protein, eaten: 80, planned: 0, target: 150),
    (kind: DiaryBudgetMacroKind.carbs, eaten: 150, planned: 0, target: 200),
    (kind: DiaryBudgetMacroKind.fat, eaten: 20, planned: 0, target: 60),
  ],
);

/// A dashboard that starts loading and then fails with nothing to show, or
/// never fails.
class _Dashboard extends DiaryDayDashboardController {
  new({required this.fails});

  final bool fails;

  @override
  DiaryDayDashboardState build(DateTime selectedDay) {
    if (fails) {
      Future<void>.delayed(Duration.zero, () {
        state = DiaryDayDashboardState(
          data: null,
          isFromCache: false,
          isRefreshing: false,
          error: StateError('read failed'),
        );
      });
    }
    return const DiaryDayDashboardState(
      data: null,
      isFromCache: false,
      isRefreshing: true,
      error: null,
    );
  }
}

/// Pumps [tile] of [size] in [mode] inside the frame of its tile, with the
/// card data [data] (null while the balance loads).
Future<void> _pump(
  WidgetTester tester,
  DiaryDashboardTile tile,
  DiaryTileSize size,
  String mode, {
  DiaryBudgetCardData? data,
  bool dashboardFails = false,
  bool allMacrosColored = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryDayDashboardControllerProvider(_day)
            .overrideWith(() => _Dashboard(fails: dashboardFails)),
        diaryBudgetCardDataProvider(_day).overrideWithValue(data),
      ],
      child: MaterialApp(
        theme: AppTheme.dark().withAllMacrosColored(value: allMacrosColored),
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
              child: tile.builder(
                DiaryTileArgs(day: _day, size: size, mode: mode),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The eaten colors of the three macro lines, in protein, carbs, fat order.
List<Color?> _eatenColors(WidgetTester tester) => [
  for (final line in tester.widgetList<DiaryBudgetLine>(
    find.byType(DiaryBudgetLine),
  ))
    line.eatenColor,
];

void main() {
  group('kcal tile', () {
    testWidgets('draws the pace marker in bar mode', (tester) async {
      await _pump(
        tester,
        diaryKcalTile,
        DiaryTileSize.s2x2,
        DiaryTileModes.bar,
        data: _data(paceKcal: 1000),
      );

      expect(find.byKey(DiaryBudgetLine.paceKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws no marker without a pace', (tester) async {
      await _pump(
        tester,
        diaryKcalTile,
        DiaryTileSize.s2x2,
        DiaryTileModes.bar,
        data: _data(),
      );

      expect(find.byType(DiaryBudgetLine), findsOneWidget);
      expect(find.byKey(DiaryBudgetLine.paceKey), findsNothing);
    });

    testWidgets('draws no marker on a pause day', (tester) async {
      await _pump(
        tester,
        diaryKcalTile,
        DiaryTileSize.s2x2,
        DiaryTileModes.bar,
        data: _data(paceKcal: 1000, isPauseDay: true),
      );

      expect(find.byType(DiaryBudgetLine), findsOneWidget);
      expect(find.byKey(DiaryBudgetLine.paceKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final (mode, size) in [
      (DiaryTileModes.bar, DiaryTileSize.s2x2),
      (DiaryTileModes.ring, DiaryTileSize.s2x2),
    ]) {
      Color? overColor(WidgetTester tester) => mode == DiaryTileModes.bar
          ? tester
                .widget<DiaryBudgetLine>(find.byType(DiaryBudgetLine))
                .overColor
          : tester.widget<DiaryTileRing>(find.byType(DiaryTileRing)).overColor;

      testWidgets('$mode: over the target is the error color for a losing '
          'goal', (tester) async {
        await _pump(
          tester,
          diaryKcalTile,
          size,
          mode,
          data: _data(metrics: _overMetrics),
        );
        final context = tester.element(find.byType(Scaffold));

        expect(overColor(tester), Theme.of(context).colorScheme.error);
      });

      testWidgets('$mode: over the target is ink for a gaining goal', (
        tester,
      ) async {
        await _pump(
          tester,
          diaryKcalTile,
          size,
          mode,
          data: _data(metrics: _overMetrics, overIsMiss: false),
        );
        final context = tester.element(find.byType(Scaffold));

        expect(overColor(tester), FoodLabelColors.of(context).ink);
      });
    }

    testWidgets('bar: over the target is muted on a pause day', (tester) async {
      await _pump(
        tester,
        diaryKcalTile,
        DiaryTileSize.s2x2,
        DiaryTileModes.bar,
        data: _data(metrics: _overMetrics, isPauseDay: true),
      );
      final context = tester.element(find.byType(Scaffold));

      expect(
        tester.widget<DiaryBudgetLine>(find.byType(DiaryBudgetLine)).overColor,
        FoodLabelColors.of(context).muted,
      );
    });
  });

  group('macros tile colors', () {
    testWidgets('only the lowest macro is colored', (tester) async {
      await _pump(
        tester,
        diaryMacrosTile,
        DiaryTileSize.s4x2,
        DiaryTileModes.bars,
        data: _data(),
      );
      final context = tester.element(find.byType(DiaryBudgetLine).first);
      final ink = FoodLabelColors.of(context).ink;

      expect(_eatenColors(tester), [
        ink,
        ink,
        diaryBudgetMacroColor(context, DiaryBudgetMacroKind.fat),
      ]);
    });

    testWidgets('all are colored when the user wants it', (tester) async {
      await _pump(
        tester,
        diaryMacrosTile,
        DiaryTileSize.s4x2,
        DiaryTileModes.bars,
        data: _data(),
        allMacrosColored: true,
      );
      final context = tester.element(find.byType(DiaryBudgetLine).first);

      expect(MetricAccentColors.of(context).allMacrosColored, isTrue);
      expect(_eatenColors(tester), [
        for (final kind in DiaryBudgetMacroKind.values)
          diaryBudgetMacroColor(context, kind),
      ]);
    });

    testWidgets('none is colored on a past day, also when all should be', (
      tester,
    ) async {
      await _pump(
        tester,
        diaryMacrosTile,
        DiaryTileSize.s4x2,
        DiaryTileModes.bars,
        data: _data(status: DiaryDayStatus.past),
        allMacrosColored: true,
      );
      final context = tester.element(find.byType(DiaryBudgetLine).first);
      final ink = FoodLabelColors.of(context).ink;

      expect(_eatenColors(tester), [ink, ink, ink]);
    });

    testWidgets('none is colored on a pause day', (tester) async {
      await _pump(
        tester,
        diaryMacrosTile,
        DiaryTileSize.s4x2,
        DiaryTileModes.bars,
        data: _data(isPauseDay: true),
        allMacrosColored: true,
      );
      final context = tester.element(find.byType(DiaryBudgetLine).first);
      final muted = FoodLabelColors.of(context).muted;

      expect(_eatenColors(tester), [muted, muted, muted]);
    });
  });

  group('load error', () {
    final message = _l10n.diaryDashboardTileLoadFailed;
    final errorIcon = find.byIcon(Icons.error_outline_rounded);

    for (final (name, tile, mode) in [
      ('kcal', diaryKcalTile, DiaryTileModes.bar),
      ('macros', diaryMacrosTile, DiaryTileModes.bars),
      ('meals', diaryMealsTile, DiaryTileModes.bars),
    ]) {
      testWidgets('$name tile shows it when the dashboard failed', (
        tester,
      ) async {
        await _pump(
          tester,
          tile,
          DiaryTileSize.s2x2,
          mode,
          data: _data(),
          dashboardFails: true,
        );

        expect(errorIcon, findsOneWidget);
        expect(tester.widget<Icon>(errorIcon).semanticLabel, message);
      });

      testWidgets('$name tile shows no error while the dashboard loads', (
        tester,
      ) async {
        await _pump(tester, tile, DiaryTileSize.s2x2, mode, data: _data());

        expect(errorIcon, findsNothing);
      });
    }
  });
}
