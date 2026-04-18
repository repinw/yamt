import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';

void main() {
  test('toNutritionMetricValue drops trailing decimals for whole numbers', () {
    expect(10.0.toNutritionMetricValue(), '10');
  });

  test('toNutritionMetricValue keeps one decimal for fractional numbers', () {
    expect(10.5.toNutritionMetricValue(), '10.5');
  });

  test('toNutritionMetricValue rounds to one decimal place', () {
    expect(10.56.toNutritionMetricValue(), '10.6');
  });

  testWidgets('NutritionMetricsStrip renders metric labels and values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NutritionMetricsStrip(
            metrics: [
              NutritionMetric(label: 'Protein', value: '12'),
              NutritionMetric(label: 'Carbs', value: '8.5'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('CARBS'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
  });
}
