import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_metric_stat_card.dart';

void main() {
  testWidgets('renders title and value with accent border', (tester) async {
    const borderColor = Colors.deepOrange;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalorieMetricStatCard(
            title: 'Today left',
            value: '650 kcal',
            borderColor: borderColor,
          ),
        ),
      ),
    );

    expect(find.text('Today left'), findsOneWidget);
    expect(find.text('650 kcal'), findsOneWidget);

    final decoratedBox = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.text('Today left'),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final border = decoration.border as Border;
    expect(border.top.color, borderColor.withValues(alpha: 0.7));
  });
}
