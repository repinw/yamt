import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_kcal_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_kcal_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

/// The grid of a phone 390 px wide, less the page's side padding.
final _metrics = DiaryDashboardMetrics.of(358, TextScaler.noScaling);

const FoodLabelColors _colors = FoodLabelColors.light;

/// A planned day with 210 kcal left after the plans, as the tile maps it.
final DiaryKcalTileView _view = (
  value: '210',
  ringValue: '210',
  caption: _l10n.diaryBudgetKcalLeftAfterPlan,
  ringCaption: _l10n.diaryBudgetKcalLeftAfterPlan,
  total: _l10n.diaryBudgetKcalEatenOfTarget('1.840', '2.050'),
  color: _colors.plan,
  eaten: 1240,
  planned: 600,
  target: 2050,
  scale: 2050,
  eatenColor: _colors.plan,
  overColor: _colors.ink,
  pace: 1200,
);

/// A pause day with 1.240 kcal eaten, as the tile maps it.
final DiaryKcalTileView _pauseView = (
  value: _l10n.diaryBalancePauseDayValue,
  ringValue: '1.240',
  caption: _l10n.diaryBudgetPauseEaten('1.240'),
  ringCaption: _l10n.diaryBalancePauseDayValue,
  total: null,
  color: _colors.muted,
  eaten: 1240,
  planned: 0,
  target: null,
  scale: 2050,
  eatenColor: _colors.muted,
  overColor: _colors.muted,
  pace: null,
);

/// Pumps the kcal tile of [size] in [mode] inside the frame of its tile,
/// with [view] or the planned day.
Future<void> _pump(
  WidgetTester tester,
  DiaryTileSize size,
  String mode, {
  DiaryKcalTileView? view,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _metrics.width(size.columns) - 2 * AppDashboard.tilePadding,
            height: _metrics.height(size.rows!) - 2 * AppDashboard.tilePadding,
            child: DiaryKcalTileLayout(
              view: view ?? _view,
              size: size,
              mode: mode,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Ring 2×1 says only the unit beside the ring', (tester) async {
    await _pump(tester, DiaryTileSize.s2x1, DiaryTileModes.ring);

    expect(find.text(_view.ringCaption), findsNothing);
    expect(find.text(_l10n.caloriesUnitKcal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ring 2×1 keeps the pause day word', (tester) async {
    await _pump(
      tester,
      DiaryTileSize.s2x1,
      DiaryTileModes.ring,
      view: _pauseView,
    );

    expect(find.text(_l10n.diaryBalancePauseDayValue), findsOneWidget);
    expect(find.text(_l10n.caloriesUnitKcal), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the other sizes and modes keep their caption', (tester) async {
    for (final (size, mode, caption) in [
      (DiaryTileSize.s2x2, DiaryTileModes.ring, _view.ringCaption),
      (DiaryTileSize.s4x1, DiaryTileModes.ring, _view.ringCaption),
      (DiaryTileSize.s2x1, DiaryTileModes.number, _view.caption),
      (DiaryTileSize.s2x2, DiaryTileModes.bar, _view.caption),
    ]) {
      await _pump(tester, size, mode);

      expect(find.text(caption), findsOneWidget, reason: '${size.name} $mode');
      expect(find.text(_l10n.caloriesUnitKcal), findsNothing);
    }
  });
}
