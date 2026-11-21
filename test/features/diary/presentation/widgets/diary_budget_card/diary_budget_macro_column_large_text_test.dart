import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/app_font_test_utils.dart';

const _metrics = DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 1000,
  eatenKcal: 1000,
  realDayLeftKcal: 1000,
  dayLeftKcal: 1000,
  targetKcal: 2000,
);

/// Grams of three different lengths: 1.070 g, 50 g, and 5 g left.
DiaryBudgetCardData _data({
  bool isPauseDay = false,
  List<DiaryBudgetMacro>? macros,
}) => DiaryBudgetCardData(
  day: DateTime(2026, 4, 27),
  status: DiaryDayStatus.today,
  metrics: _metrics,
  isPauseDay: isPauseDay,
  macros:
      macros ??
      const [
        (
          kind: DiaryBudgetMacroKind.protein,
          eaten: 80,
          planned: 20,
          target: 1170,
        ),
        (kind: DiaryBudgetMacroKind.carbs, eaten: 150, planned: 0, target: 200),
        (kind: DiaryBudgetMacroKind.fat, eaten: 55, planned: 0, target: 60),
      ],
);

Future<void> _pump(
  WidgetTester tester,
  DiaryBudgetCardData data, {
  required double width,
  required double textScale,
  String locale = 'de',
  bool showDetails = false,
  bool showEaten = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
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
              width: width,
              child: DiaryBudgetMacroColumn(
                data: data,
                showDetails: showDetails,
                showEaten: showEaten,
                numberFormat: NumberFormat.decimalPattern(locale),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _value(WidgetTester tester, DiaryBudgetMacroKind kind) =>
    tester.getRect(find.byKey(DiaryBudgetCardKeys.macroValue(kind)));

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['de', 'en']) {
    final l10n = lookupAppLocalizations(Locale(locale));

    for (final width in [160.0, 130.0]) {
      for (final showEaten in [false, true]) {
        for (final showDetails in [false, true]) {
          testWidgets(
            'at text size 2 and ${width.round()} dp the grams sit under their '
            'names at one size in $locale'
            '${showEaten ? ' showing eaten' : ''}'
            '${showDetails ? ' with details' : ''}',
            (tester) async {
              await _pump(
                tester,
                _data(),
                width: width,
                textScale: 2,
                locale: locale,
                showEaten: showEaten,
                showDetails: showDetails,
              );

              expect(tester.takeException(), isNull);

              final heights = <double>[];
              for (final kind in DiaryBudgetMacroKind.values) {
                final name = tester.getRect(
                  find.text(diaryBudgetMacroLabel(l10n, kind)),
                );
                final value = _value(tester, kind);
                // Stacked: the grams start below the name's line.
                expect(
                  value.top,
                  greaterThanOrEqualTo(name.bottom - 0.5),
                  reason: kind.name,
                );
                expect(value.right, lessThanOrEqualTo(width + 0.01));
                heights.add(value.height);
              }
              expect(heights[1], closeTo(heights[0], 0.01));
              expect(heights[2], closeTo(heights[0], 0.01));
            },
          );
        }
      }
    }

    testWidgets('at normal text size the grams sit beside their names in '
        '$locale', (tester) async {
      await _pump(tester, _data(), width: 300, textScale: 1, locale: locale);

      expect(tester.takeException(), isNull);
      for (final kind in DiaryBudgetMacroKind.values) {
        final name = tester.getRect(
          find.text(diaryBudgetMacroLabel(l10n, kind)),
        );
        final value = _value(tester, kind);
        expect(value.left, greaterThanOrEqualTo(name.right - 0.5));
        expect(value.center.dy, lessThan(name.bottom + 8));
      }
    });
  }

  testWidgets('without macros the column draws nothing and does not crash', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await _pump(
        tester,
        _data(macros: const []),
        width: 130,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
      for (final kind in DiaryBudgetMacroKind.values) {
        expect(find.byKey(DiaryBudgetCardKeys.macroValue(kind)), findsNothing);
      }
    }
  });

  testWidgets('a pause day at text size 2 keeps the grams at one size', (
    tester,
  ) async {
    await _pump(
      tester,
      _data(isPauseDay: true),
      width: 130,
      textScale: 2,
      showDetails: true,
    );

    expect(tester.takeException(), isNull);
    final heights = [
      for (final kind in DiaryBudgetMacroKind.values)
        _value(tester, kind).height,
    ];
    expect(heights[1], closeTo(heights[0], 0.01));
    expect(heights[2], closeTo(heights[0], 0.01));
  });
}
