import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
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
                share: 0.5,
              ),
              StatisticsMacroShare(
                type: StatisticsMacroType.protein,
                grams: 60,
                share: 0.25,
              ),
              StatisticsMacroShare(
                type: StatisticsMacroType.fat,
                grams: 30,
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
    expect(
      find.byKey(const ValueKey('statistics-macro-share-segment-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('statistics-macro-share-segment-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('statistics-macro-share-segment-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('statistics-macro-share-empty-bar')),
      findsNothing,
    );
  });

  testWidgets(
    'StatisticsMacroShareChart renders neutral bar when all shares are zero',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsMacroShareChart(
              items: const [
                StatisticsMacroShare(
                  type: StatisticsMacroType.carbs,
                  grams: 0,
                  share: 0,
                ),
                StatisticsMacroShare(
                  type: StatisticsMacroType.protein,
                  grams: 0,
                  share: 0,
                ),
                StatisticsMacroShare(
                  type: StatisticsMacroType.fat,
                  grams: 0,
                  share: 0,
                ),
              ],
              labelBuilder: (item) => item.type.name,
              valueLabelBuilder: (item) => '${item.grams.round()} g',
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('statistics-macro-share-empty-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('statistics-macro-share-segment-0')),
        findsNothing,
      );
      expect(find.text('0 g'), findsNWidgets(3));
    },
  );
}
