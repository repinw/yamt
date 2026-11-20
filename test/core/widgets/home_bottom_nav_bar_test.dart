import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_nav_action.dart';
import 'package:yamt/core/widgets/home_nav_entry.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

const _tabs = ['Tagebuch', 'Vorrat', 'Kochbuch', 'Fortschritt'];

HomeBottomNavBar _bar() => HomeBottomNavBar(
  entries: [
    for (final (index, label) in _tabs.indexed)
      HomeNavEntry(
        item: HomeNavItem(icon: Icons.circle, label: label),
        isSelected: index == 0,
        onTap: () {},
      ),
  ],
  action: HomeNavAction(label: 'Hinzufügen', onPressed: () {}),
);

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  Widget Function(Widget bar)? around,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        extendBody: true,
        body: around == null
            ? Align(alignment: Alignment.bottomCenter, child: _bar())
            : around(_bar()),
      ),
    ),
  );
  await tester.pump();
}

double _barHeight(WidgetTester tester) =>
    tester.getSize(find.byKey(HomeBottomNavBar.actionKey)).height;

void main() {
  group('HomeBottomNavBar', () {
    testWidgets('is navBarHeight tall at normal text', (tester) async {
      await _pump(tester, width: 400, textScale: 1);

      expect(tester.takeException(), isNull);
      expect(_barHeight(tester), AppGraphit.navBarHeight);
    });

    for (final width in [700.0, 360.0]) {
      testWidgets('grows without overflow at text scale 2.0 and ${width}px', (
        tester,
      ) async {
        await _pump(tester, width: width, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(_barHeight(tester), greaterThan(AppGraphit.navBarHeight));
      });
    }

    testWidgets('the last content row clears a grown bar at text scale 2.0', (
      tester,
    ) async {
      const lastRow = Key('last-row');
      await _pump(
        tester,
        width: 360,
        textScale: 2,
        around: (bar) => Stack(
          children: [
            Builder(
              builder: (context) => ListView(
                padding: EdgeInsets.only(
                  bottom: homeShellPageBottomPadding(context),
                ),
                children: [
                  for (var i = 0; i < 30; i += 1) const SizedBox(height: 48),
                  const SizedBox(key: lastRow, height: 48),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: bar),
          ],
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pump();

      final rowBottom = tester.getBottomLeft(find.byKey(lastRow)).dy;
      final barTop = tester
          .getTopLeft(find.byKey(HomeBottomNavBar.actionKey))
          .dy;
      expect(_barHeight(tester), greaterThan(AppGraphit.navBarHeight));
      expect(
        rowBottom,
        lessThanOrEqualTo(barTop - AppSpacing.xs),
        reason: 'the last row ends at $rowBottom, the bar starts at $barTop',
      );
    });
  });
}
