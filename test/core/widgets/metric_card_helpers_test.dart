import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

void main() {
  testWidgets('metric frame uses solid card surface and subtle border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(seedColor: AppColors.seed),
        home: const Scaffold(
          body: MetricCardFrame(
            child: SizedBox(key: ValueKey<String>('metric-child')),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(MetricCardFrame));
    final colors = Theme.of(context).colorScheme;
    final frame = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = frame.decoration as BoxDecoration;

    expect(decoration.color, AppQuietSurfaces.cardDecoration(colors).color);
    expect(
      (decoration.border as Border?)?.top.color,
      (AppQuietSurfaces.cardDecoration(colors).border as Border?)?.top.color,
    );
    expect(decoration.boxShadow, isNotEmpty);
    expect(find.byKey(const ValueKey<String>('metric-child')), findsOneWidget);
  });

  testWidgets('metric detail shell applies requested padding around content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(seedColor: AppColors.seed),
        home: const Scaffold(
          body: MetricDetailCardShell(
            child: Text('Detail content'),
          ),
        ),
      ),
    );

    expect(find.text('Detail content'), findsOneWidget);
    expect(find.byType(Padding), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
