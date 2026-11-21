import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_ledger.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/app_font_test_utils.dart';

/// A day with a left value of nine digits, wider than half of a narrow row.
const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 0,
  eatenKcal: 0,
  realDayLeftKcal: 123456789,
  dayLeftKcal: 123456789,
  targetKcal: 123456789,
);

Future<void> _pump(WidgetTester tester, double textScale) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: page!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: DiaryBudgetLedger(
                data: DiaryBudgetCardData(
                  day: DateTime(2026, 4, 27),
                  status: DiaryDayStatus.today,
                  metrics: _metrics,
                  isPauseDay: false,
                  macros: const [],
                ),
                numberFormat: NumberFormat.decimalPattern('de'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Width of the value box of the total row, and of the whole row.
(double, double) _valueAndRow(WidgetTester tester) {
  final total = find.byKey(DiaryBudgetCardKeys.ledgerTotal);
  final value = find.descendant(of: total, matching: find.byType(FittedBox));
  return (tester.getSize(value).width, tester.getSize(total).width);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('at text size 2 a ledger value takes at most its share of the '
      'row and shrinks', (tester) async {
    await _pump(tester, 2);

    expect(tester.takeException(), isNull);
    final (value, row) = _valueAndRow(tester);
    expect(value, lessThanOrEqualTo(row * AppBudgetCard.ledgerValueMaxShare));
    expect(AppBudgetCard.ledgerValueMaxShare, 0.5);
    // The value shrank: it is drawn narrower than its text sets.
    final text = find.text('123.456.789');
    expect(
      tester.getBottomRight(text).dx - tester.getTopLeft(text).dx,
      lessThan(tester.getSize(text).width - 1),
    );
  });

  testWidgets('at normal text a ledger value stays uncapped', (tester) async {
    await _pump(tester, 1);

    final (value, row) = _valueAndRow(tester);
    expect(value, greaterThan(row * AppBudgetCard.ledgerValueMaxShare));
    final text = find.text('123.456.789');
    expect(
      tester.getBottomRight(text).dx - tester.getTopLeft(text).dx,
      closeTo(tester.getSize(text).width, 0.01),
    );
  });
}
