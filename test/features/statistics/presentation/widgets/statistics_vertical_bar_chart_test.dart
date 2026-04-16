import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_vertical_bar_chart.dart';

void main() {
  testWidgets('StatisticsVerticalBarChart shows labels and values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatisticsVerticalBarChart(
            data: [
              StatisticsBarChartDatum(
                label: 'Mo',
                value: 100,
                valueLabel: '100',
              ),
              StatisticsBarChartDatum(
                label: 'Di',
                value: 150,
                goalValue: 120,
                valueLabel: '150',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Di'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
  });
}
