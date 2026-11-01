import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_kcal_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 800,
  eatenKcal: 800,
  realDayLeftKcal: 1200,
  dayLeftKcal: 1200,
  targetKcal: 2000,
);

DiaryBudgetCardData _data({double? paceKcal, bool isPauseDay = false}) =>
    DiaryBudgetCardData(
      day: DateTime(2026, 4, 27),
      status: DiaryDayStatus.today,
      metrics: _metrics,
      isPauseDay: isPauseDay,
      macros: const [],
      paceKcal: paceKcal,
    );

Future<void> _pump(WidgetTester tester, DiaryBudgetCardData data) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: DiaryBudgetKcalColumn(
              data: data,
              showDetails: false,
              showEaten: false,
              numberFormat: NumberFormat.decimalPattern('en'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('marks the pace on its kcal line where the data puts it', (
    tester,
  ) async {
    await _pump(tester, _data(paceKcal: 1000));

    expect(find.byKey(DiaryBudgetLine.paceKey), findsOneWidget);
    final line = tester.getRect(find.byType(DiaryBudgetLine));
    final marker = tester.getCenter(find.byKey(DiaryBudgetLine.paceKey));
    // Half of the target on a line that reaches 120 % of it.
    expect(
      marker.dx - line.left,
      closeTo(line.width * 0.5 / AppBudgetCard.lineScale, 1e-6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks nothing without a pace', (tester) async {
    await _pump(tester, _data());

    expect(find.byType(DiaryBudgetLine), findsOneWidget);
    expect(find.byKey(DiaryBudgetLine.paceKey), findsNothing);
  });

  testWidgets('a pause day marks nothing', (tester) async {
    await _pump(tester, _data(paceKcal: 1000, isPauseDay: true));

    expect(find.byType(DiaryBudgetLine), findsOneWidget);
    expect(find.byKey(DiaryBudgetLine.paceKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
