import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

void main() {
  testWidgets('metric detail shell applies requested padding around content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: MetricDetailCardShell(child: Text('Detail content')),
        ),
      ),
    );

    expect(find.text('Detail content'), findsOneWidget);
    expect(find.byType(Padding), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
