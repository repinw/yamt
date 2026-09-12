import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart.dart';

void main() {
  testWidgets('uses a full seven-day x-axis for sparse weight data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TdeeWeightChart(
            points: <TdeeAnalyticsPoint>[
              TdeeAnalyticsPoint(
                day: DateTime(2026, 6),
                scaleWeightKg: 80,
              ),
            ],
          ),
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
      MaterialApp(
        home: Scaffold(
          body: TdeeWeightChart(
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
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxX, 6);
    expect(find.text('6/1'), findsOneWidget);
    expect(find.text('6/7'), findsOneWidget);
    expect(find.text('Ziel 75.0 kg'), findsNothing);
  });
}
