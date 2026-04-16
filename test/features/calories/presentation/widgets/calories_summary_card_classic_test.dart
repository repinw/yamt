import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_adjustments.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_gauge.dart';

void main() {
  final numberFormat = NumberFormat.decimalPattern('en');

  testWidgets('classic hero hides adjustment chips when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: SizedBox(
          width: 360,
          child: ClassicSummaryHero(
            remainingKcal: 400,
            color: const Color(0xFF10B981),
            consumedKcal: 1600,
            baseGoalKcal: 2000,
            activityDeltaKcal: 0,
            availableActivityDeltaKcal: 0,
            carryoverKcal: 0,
            availableCarryoverKcal: 0,
            label: 'Remaining',
            numberFormat: numberFormat,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('400'), findsOneWidget);
    expect(find.text('REMAINING'), findsOneWidget);
    expect(find.byType(ClassicSummaryAdjustmentsPill), findsNothing);
    expect(find.byType(ClassicSummaryGauge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic hero shows both adjustment chips when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: SizedBox(
          width: 360,
          child: ClassicSummaryHero(
            remainingKcal: 650,
            color: const Color(0xFF10B981),
            consumedKcal: 1350,
            baseGoalKcal: 2000,
            activityDeltaKcal: 250,
            availableActivityDeltaKcal: 250,
            carryoverKcal: 150,
            availableCarryoverKcal: 150,
            label: 'Remaining',
            numberFormat: numberFormat,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClassicSummaryAdjustmentsPill), findsOneWidget);
    expect(find.text('+250'), findsOneWidget);
    expect(find.text('+150'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic adjustment pill keeps the negative carryover sign', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: ClassicSummaryAdjustmentsPill(
          activityDeltaKcal: 0,
          carryoverKcal: -120,
          numberFormat: numberFormat,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('-120'), findsOneWidget);
    expect(find.text('+120'), findsNothing);
  });

  testWidgets('classic gauge paints safely when all segments are zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: const SizedBox(
          width: 360,
          height: 220,
          child: ClassicSummaryGauge(
            strokeWidth: 32,
            color: Color(0xFF10B981),
            consumedKcal: 0,
            baseGoalKcal: 0,
            activityDeltaKcal: 0,
            availableActivityDeltaKcal: 0,
            carryoverKcal: 0,
            availableCarryoverKcal: 0,
            trackColor: Color(0xFF374151),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClassicSummaryGauge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildHarness({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}
