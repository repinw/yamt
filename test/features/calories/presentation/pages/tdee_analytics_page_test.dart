import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/presentation/pages/tdee_analytics_page.dart';

void main() {
  group('TdeeAnalyticsPage', () {
    final now = DateTime(2025, 3, 10);
    final cycle = TdeeAnalyticsGoalCycle(
      id: 'cycle_1',
      title: 'Abnehmen',
      startDate: DateTime(2025),
      goalMode: CalorieGoalMode.lose,
      startWeightKg: 85,
      targetWeightKg: 75,
    );

    final fakeState = TdeeAnalyticsState(
      selectedCycle: cycle,
      availableCycles: [cycle],
      timeRange: TdeeAnalyticsTimeRange.days28,
      points: [
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3),
          learnedBaseTdeeKcal: 2400,
          totalTdeeKcal: 2600,
          scaleWeightKg: 80,
        ),
        TdeeAnalyticsPoint(
          day: DateTime(2025, 3, 2),
          learnedBaseTdeeKcal: 2420,
          totalTdeeKcal: 2650,
          scaleWeightKg: 79.8,
        ),
      ],
      summary: const TdeeAnalyticsSummary(
        averageTdeeKcal: 2410,
        tdeeDifferenceKcal: 20,
        threeDayDeltaKcal: 20,
        sevenDayDeltaKcal: 20,
        fourteenDayDeltaKcal: 20,
      ),
      anticipation: TdeeAnticipationProjection(
        currentWeightKg: 79.8,
        targetWeightKg: 75,
        trendSpeedKgPerWeek: -0.7,
        projectedDate: now.add(const Duration(days: 48)),
        daysRemaining: 48,
        projectionPoints: const [],
      ),
    );

    testWidgets('renders header, charts, chips, and insights card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tdeeAnalyticsProvider.overrideWith(
              (ref, query) => Future.value(fakeState),
            ),
          ],
          child: const MaterialApp(
            home: TdeeAnalyticsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TDEE & Verbrauch'), findsOneWidget);
      expect(find.text('2410'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('7 T'), findsOneWidget);
      expect(find.text('28 T'), findsOneWidget);
      expect(find.text('Insights & Veränderungen'), findsOneWidget);
      expect(find.textContaining('75.0 kg'), findsWidgets);
    });
  });
}
