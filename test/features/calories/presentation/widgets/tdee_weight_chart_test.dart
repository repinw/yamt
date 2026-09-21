import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart.dart';
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
    expect(find.text('Ziel 75.0 kg'), findsNothing);
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
}
