import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';

HomeHeaderTool _tool(String label, IconData icon, {int? badge}) =>
    HomeHeaderTool(
      symbol: Icon(icon),
      label: label,
      badgeCount: badge,
      onPressed: () {},
    );

void main() {
  testWidgets('the leading menu and three tools fit 320px at text scale 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          appBar: HomeTopBar(
            title: 'Tagebuch',
            leading: _tool('Menü', Icons.menu),
            tools: [
              _tool('Neu', Icons.add),
              _tool('Töpfe', Icons.soup_kitchen),
              _tool('Einkauf', Icons.shopping_cart, badge: 12),
            ],
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Menü'), findsOneWidget);
    expect(find.text('Einkauf'), findsOneWidget);
    expect(tester.getSize(find.text('Tagebuch')).width, greaterThan(0));
    final bar = tester.getRect(find.byType(HomeTopBar));
    for (final label in ['Menü', 'Neu', 'Töpfe', 'Einkauf']) {
      final rect = tester.getRect(find.widgetWithText(HomeHeaderTool, label));
      expect(rect.left, greaterThanOrEqualTo(bar.left), reason: label);
      expect(rect.right, lessThanOrEqualTo(bar.right), reason: label);
    }
  });
}
