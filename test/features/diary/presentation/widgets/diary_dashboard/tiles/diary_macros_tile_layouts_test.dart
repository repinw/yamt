import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('de'));

/// The grid of a phone 390 px wide, less the page's side padding.
final _metrics = DiaryDashboardMetrics.of(358, TextScaler.noScaling);

const FoodLabelColors _colors = FoodLabelColors.light;

DiaryMacroTileView _macro(
  DiaryBudgetMacroKind kind,
  String letter, {
  required double eaten,
  required double target,
}) => (
  letter: letter,
  label: diaryBudgetMacroLabel(_l10n, kind),
  value: '${(target - eaten).round()} g',
  total: _l10n.diaryMacroEatenOfTarget('${eaten.round()}', '${target.round()}'),
  labelColor: _colors.ink,
  valueColor: _colors.ink,
  eaten: eaten,
  planned: 0,
  target: target,
  scale: target,
  eatenColor: _colors.accent,
);

final List<DiaryMacroTileView> _macros = [
  _macro(
    DiaryBudgetMacroKind.protein,
    _l10n.diaryDashboardMacroProteinShort,
    eaten: 88,
    target: 128,
  ),
  _macro(
    DiaryBudgetMacroKind.carbs,
    _l10n.diaryDashboardMacroCarbsShort,
    eaten: 134,
    target: 231,
  ),
  _macro(
    DiaryBudgetMacroKind.fat,
    _l10n.diaryDashboardMacroFatShort,
    eaten: 40,
    target: 68,
  ),
];

/// Pumps the macros in mode Zahlen inside the frame of a tile of [size].
Future<void> _pumpNumbers(WidgetTester tester, DiaryTileSize size) {
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
            child: DiaryMacrosTileLayout(
              macros: _macros,
              size: size,
              mode: DiaryTileModes.numbers,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Zahlen shows eaten of target only on two full-width rows', (
    tester,
  ) async {
    for (final (size, name, withTotal) in [
      (DiaryTileSize.s2x1, (DiaryMacroTileView m) => m.letter, false),
      (DiaryTileSize.s2x2, (DiaryMacroTileView m) => m.letter, false),
      (DiaryTileSize.s4x1, (DiaryMacroTileView m) => m.label, false),
      (DiaryTileSize.s4x2, (DiaryMacroTileView m) => m.label, true),
    ]) {
      await _pumpNumbers(tester, size);

      for (final macro in _macros) {
        expect(find.text(name(macro)), findsOneWidget, reason: size.name);
        expect(
          find.text(macro.total!),
          withTotal ? findsOneWidget : findsNothing,
          reason: '${size.name} ${macro.total}',
        );
      }
      expect(tester.takeException(), isNull, reason: size.name);
    }
  });
}
