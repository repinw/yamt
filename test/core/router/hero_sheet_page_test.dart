import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/router/hero_sheet_page.dart';

const _sourceKey = Key('source');
const _targetKey = Key('target');
const _sheetKey = Key('sheet');

Widget _app() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/sheet'),
              child: const Hero(
                tag: 'image',
                child: SizedBox.square(key: _sourceKey, dimension: 40),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/sheet',
        pageBuilder: (context, state) => const HeroSheetPage<void>(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              key: _sheetKey,
              height: 300,
              width: double.infinity,
              child: Material(
                child: Hero(
                  tag: 'image',
                  child: SizedBox(key: _targetKey, height: 200),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('flies the hero from the page into the sheet', (tester) async {
    await tester.pumpWidget(_app());
    final start = tester.getRect(find.byKey(_sourceKey));

    await tester.tap(find.byKey(_sourceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final midFlight = tester.getRect(find.byKey(_targetKey));
    await tester.pumpAndSettle();
    final end = tester.getRect(find.byKey(_targetKey));

    expect(midFlight, isNot(start));
    expect(midFlight, isNot(end));
    expect(midFlight.top, greaterThan(start.top));
    expect(midFlight.top, lessThan(end.top));
  });

  testWidgets('keeps the page below visible', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(_sourceKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetKey), findsOneWidget);
    expect(find.byKey(_sourceKey, skipOffstage: false), findsOneWidget);
    expect(find.byType(ModalBarrier), findsWidgets);
  });

  testWidgets('closes on a long downward drag', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(_sourceKey));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(_sheetKey), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.byKey(_sheetKey), findsOneWidget);

    await tester.drag(find.byKey(_sheetKey), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.byKey(_sheetKey), findsNothing);
  });

  testWidgets('closes on a tap on the barrier', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(_sourceKey));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();

    expect(find.byKey(_sheetKey), findsNothing);
  });
}
