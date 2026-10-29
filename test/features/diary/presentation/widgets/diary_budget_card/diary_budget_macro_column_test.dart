import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_column.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 1000,
  eatenKcal: 1000,
  realDayLeftKcal: 1000,
  dayLeftKcal: 1000,
  targetKcal: 2000,
);

DiaryBudgetCardData _data({
  bool isPauseDay = false,
  DiaryDayStatus status = DiaryDayStatus.today,
  double fatEaten = 20,
  double proteinPlanned = 0,
}) => DiaryBudgetCardData(
  day: DateTime(2026, 4, 27),
  status: status,
  metrics: _metrics,
  isPauseDay: isPauseDay,
  macros: [
    (
      kind: DiaryBudgetMacroKind.protein,
      eaten: 80,
      planned: proteinPlanned,
      target: 150,
    ),
    (kind: DiaryBudgetMacroKind.carbs, eaten: 150, planned: 0, target: 200),
    (kind: DiaryBudgetMacroKind.fat, eaten: fatEaten, planned: 0, target: 60),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  DiaryBudgetCardData data, {
  bool showDetails = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: DiaryBudgetMacroColumn(
            data: data,
            showDetails: showDetails,
            showEaten: false,
            numberFormat: NumberFormat.decimalPattern('en'),
          ),
        ),
      ),
    ),
  );
}

Text _value(WidgetTester tester, DiaryBudgetMacroKind kind) =>
    tester.widget<Text>(find.byKey(DiaryBudgetCardKeys.macroValue(kind)));

void main() {
  testWidgets('shows the grams left and colors the lowest macro', (
    tester,
  ) async {
    await _pump(tester, _data());
    final context = tester.element(find.byType(DiaryBudgetMacroColumn));
    final colors = FoodLabelColors.of(context);

    expect(_value(tester, DiaryBudgetMacroKind.protein).data, '70 g');
    expect(_value(tester, DiaryBudgetMacroKind.carbs).data, '50 g');
    expect(_value(tester, DiaryBudgetMacroKind.fat).data, '40 g');
    // Fat has the lowest share, so it takes its color in the dark theme.
    expect(
      _value(tester, DiaryBudgetMacroKind.fat).style?.color,
      MetricAccentColors.of(context).fat,
    );
    expect(
      _value(tester, DiaryBudgetMacroKind.protein).style?.color,
      colors.ink,
    );
  });

  testWidgets('an overage keeps its text in ink', (tester) async {
    await _pump(tester, _data(fatEaten: 75));
    final colors = FoodLabelColors.of(
      tester.element(find.byType(DiaryBudgetMacroColumn)),
    );

    final fat = _value(tester, DiaryBudgetMacroKind.fat);
    expect(fat.data, '+15 g');
    expect(fat.style?.color, colors.ink);
  });

  testWidgets('a past day colors no macro', (tester) async {
    await _pump(tester, _data(status: DiaryDayStatus.past));
    final colors = FoodLabelColors.of(
      tester.element(find.byType(DiaryBudgetMacroColumn)),
    );

    for (final kind in DiaryBudgetMacroKind.values) {
      expect(_value(tester, kind).style?.color, colors.ink);
    }
  });

  testWidgets('a pause day shows the eaten grams in grey', (tester) async {
    await _pump(tester, _data(isPauseDay: true), showDetails: true);
    final colors = FoodLabelColors.of(
      tester.element(find.byType(DiaryBudgetMacroColumn)),
    );

    final protein = _value(tester, DiaryBudgetMacroKind.protein);
    expect(protein.data, '80 g');
    expect(protein.style?.color, colors.muted);
    expect(find.text('80 g eaten'), findsOneWidget);
  });

  testWidgets('details show eaten of target and the counted plans', (
    tester,
  ) async {
    await _pump(tester, _data(proteinPlanned: 20), showDetails: true);

    final total = tester.widget<Text>(
      find.byKey(DiaryBudgetCardKeys.macroTotal(DiaryBudgetMacroKind.protein)),
    );
    expect(total.textSpan!.toPlainText(), '100 / 150 g\n20 planned');
    expect(_value(tester, DiaryBudgetMacroKind.protein).data, '50 g');
  });
}
