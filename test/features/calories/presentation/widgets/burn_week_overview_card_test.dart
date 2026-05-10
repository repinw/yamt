import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_overview_card.dart';

void main() {
  testWidgets('renders counters, info button, bar and stat cards', (
    tester,
  ) async {
    var heartTapped = 0;
    var infoTapped = 0;
    const metrics = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.5,
      targetKcal: 7000,
      consumedKcal: 6400,
      safeZoneMinKcal: 5000,
      safeZoneMaxKcal: 9000,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BurnWeekOverviewCard(
            title: 'Week 2 day 3',
            metrics: metrics,
            numberFormat: NumberFormat.decimalPattern('en'),
            kcalUnit: 'kcal',
            starCount: 2,
            heartCount: 3,
            onHeartTap: () => heartTapped += 1,
            onInfoPressed: () => infoTapped += 1,
            infoTooltip: 'Show details',
            primaryStat: const BurnWeekOverviewStatData(
              title: 'EATEN',
              value: '1200 kcal',
              borderColor: Colors.orange,
            ),
            secondaryStat: const BurnWeekOverviewStatData(
              title: 'TODAY LEFT',
              value: '800 kcal',
              borderColor: Colors.green,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Week 2 day 3'), findsOneWidget);
    expect(find.text('x 2'), findsOneWidget);
    expect(find.text('x 3'), findsOneWidget);
    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('TODAY LEFT'), findsOneWidget);
    expect(find.text('1200 kcal'), findsOneWidget);
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.byTooltip('Show details'), findsOneWidget);

    await tester.tap(find.text('x 3'));
    await tester.pump();
    expect(heartTapped, 1);

    await tester.tap(find.byTooltip('Show details'));
    await tester.pump();
    expect(infoTapped, 1);
  });

  testWidgets('renders zero star counter too', (tester) async {
    const metrics = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.5,
      targetKcal: 7000,
      consumedKcal: 6400,
      safeZoneMinKcal: 5000,
      safeZoneMaxKcal: 9000,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BurnWeekOverviewCard(
            title: 'Week 1 day 1',
            metrics: metrics,
            numberFormat: NumberFormat.decimalPattern('en'),
            kcalUnit: 'kcal',
            starCount: 0,
            heartCount: 3,
            primaryStat: const BurnWeekOverviewStatData(
              title: 'EATEN',
              value: '0 kcal',
              borderColor: Colors.orange,
            ),
            secondaryStat: const BurnWeekOverviewStatData(
              title: 'TODAY LEFT',
              value: '2000 kcal',
              borderColor: Colors.green,
            ),
          ),
        ),
      ),
    );

    expect(find.text('x 0'), findsOneWidget);
    expect(find.text('x 3'), findsOneWidget);
  });
}
