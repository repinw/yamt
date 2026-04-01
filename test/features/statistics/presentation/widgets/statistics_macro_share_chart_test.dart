import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/statistics/domain/statistics_metrics.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_macro_share_chart.dart';

void main() {
  testWidgets('StatisticsMacroShareChart renders labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsMacroShareChart(
            items: const [
              StatisticsMacroShare(
                type: StatisticsMacroType.carbs,
                grams: 120,
                kcal: 480,
                share: 0.5,
              ),
              StatisticsMacroShare(
                type: StatisticsMacroType.protein,
                grams: 60,
                kcal: 240,
                share: 0.25,
              ),
              StatisticsMacroShare(
                type: StatisticsMacroType.fat,
                grams: 30,
                kcal: 270,
                share: 0.25,
              ),
            ],
            labelBuilder: (item) => item.type.name,
            valueLabelBuilder: (item) => '${item.grams.round()} g',
          ),
        ),
      ),
    );

    expect(find.text('carbs'), findsOneWidget);
    expect(find.text('protein'), findsOneWidget);
    expect(find.text('fat'), findsOneWidget);
    expect(find.text('120 g'), findsOneWidget);
  });
}
