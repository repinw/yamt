import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _harness(TdeeWeightChart chart) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: chart),
  );
}

void main() {
  testWidgets('uses a full seven-day x-axis for sparse weight data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        TdeeWeightChart(
          points: <TdeeAnalyticsPoint>[
            TdeeAnalyticsPoint(day: DateTime(2026, 6), scaleWeightKg: 80),
          ],
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minX, 0);
    expect(chart.data.maxX, 6);
    expect(find.text('6/1'), findsOneWidget);
    expect(find.text('6/7'), findsOneWidget);
  });

  testWidgets('seven-day filter does not extend to projected goal date', (
    tester,
  ) async {
    final firstDay = DateTime(2026, 6);
    await tester.pumpWidget(
      _harness(
        TdeeWeightChart(
          points: <TdeeAnalyticsPoint>[
            TdeeAnalyticsPoint(day: firstDay, scaleWeightKg: 80),
          ],
          anticipation: TdeeAnticipationProjection(
            currentWeightKg: 80,
            targetWeightKg: 75,
            trendSpeedKgPerWeek: -0.5,
            projectedDate: firstDay.add(const Duration(days: 70)),
            daysRemaining: 70,
            projectionPoints: <TdeeProjectionPoint>[
              TdeeProjectionPoint(
                day: firstDay.add(const Duration(days: 70)),
                weightKg: 75,
              ),
            ],
          ),
          extendToProjectedGoal: false,
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxX, 6);
    expect(find.text('Goal 75.0 kg'), findsNothing);
  });

  testWidgets('marks the reached date of a selected goal cycle', (
    tester,
  ) async {
    final firstDay = DateTime(2026, 6);
    await tester.pumpWidget(
      _harness(
        TdeeWeightChart(
          points: <TdeeAnalyticsPoint>[
            for (var i = 0; i < 10; i++)
              TdeeAnalyticsPoint(
                day: firstDay.add(Duration(days: i)),
                scaleWeightKg: 80 - i * 0.1,
              ),
          ],
          goalCycles: <TdeeAnalyticsGoalCycle>[
            TdeeAnalyticsGoalCycle(
              id: 'cycle',
              title: 'Lose',
              startDate: firstDay,
              reachedDate: firstDay.add(const Duration(days: 8)),
            ),
          ],
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final lines = chart.data.extraLinesData.verticalLines;
    expect(lines, hasLength(1));
    expect(lines.single.x, 8);
  });

  testWidgets('draws the trend as a line and scale weights as dots', (
    tester,
  ) async {
    final firstDay = DateTime(2026, 6);
    await tester.pumpWidget(
      _harness(
        TdeeWeightChart(
          points: <TdeeAnalyticsPoint>[
            TdeeAnalyticsPoint(
              day: firstDay,
              scaleWeightKg: 80,
              trendWeightKg: 80,
            ),
            TdeeAnalyticsPoint(
              day: firstDay.add(const Duration(days: 1)),
              trendWeightKg: 80.1,
            ),
            TdeeAnalyticsPoint(
              day: firstDay.add(const Duration(days: 2)),
              scaleWeightKg: 83,
              trendWeightKg: 80.3,
            ),
          ],
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final bars = chart.data.lineBarsData;
    expect(bars, hasLength(2));
    final trend = bars[TdeeWeightChartBuilder.trendBarIndex];
    final dots = bars[TdeeWeightChartBuilder.scaleBarIndex];
    expect(trend.spots.map((spot) => spot.y), [80, 80.1, 80.3]);
    expect(trend.dotData.show, isFalse);
    expect(dots.spots.map((spot) => spot.x), [0, 2]);
    expect(dots.barWidth, 0);
    expect(dots.dotData.show, isTrue);
    // The 83 kg spike stays inside the visible range.
    expect(chart.data.maxY, greaterThanOrEqualTo(84));
  });

  testWidgets('shows trend weight numbers above the chart', (tester) async {
    await tester.pumpWidget(
      _harness(
        TdeeWeightChart(
          points: <TdeeAnalyticsPoint>[
            TdeeAnalyticsPoint(
              day: DateTime(2026, 6),
              scaleWeightKg: 80,
              trendWeightKg: 80,
            ),
          ],
          summary: const TdeeAnalyticsSummary(
            averageTdeeKcal: 2400,
            tdeeDifferenceKcal: 0,
            currentWeightKg: 79.46,
            weightChangeKg: -1.24,
            weeklyRateKg: -0.456,
          ),
        ),
      ),
    );

    expect(find.text('Trend weight'), findsOneWidget);
    expect(find.text('79.5 kg'), findsOneWidget);
    expect(find.text('-1.2 kg'), findsOneWidget);
    expect(find.text('-0.46 kg'), findsOneWidget);
  });
}
