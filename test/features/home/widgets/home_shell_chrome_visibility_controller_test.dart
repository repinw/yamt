import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome_visibility_controller.dart';

void main() {
  const listKey = ValueKey<String>('inner-list');

  Future<HomeShellChromeVisibilityController> pumpScrollBody(
    WidgetTester tester,
    Widget Function(Widget list) wrapList,
  ) async {
    final controller = HomeShellChromeVisibilityController();
    addTearDown(controller.dispose);
    final list = ListView(
      key: listKey,
      children: [
        for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('$i')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationListener<ScrollNotification>(
          onNotification: controller.handleScrollNotification,
          child: wrapList(list),
        ),
      ),
    );
    return controller;
  }

  testWidgets('scrolling down hides the chrome', (tester) async {
    final controller = await pumpScrollBody(tester, (list) => list);

    await tester.drag(find.byKey(listKey), const Offset(0, -400));
    await tester.pump();

    expect(controller.visibility, lessThan(1));
  });

  testWidgets('a list inside a horizontal pager still hides the chrome', (
    tester,
  ) async {
    final controller = await pumpScrollBody(
      tester,
      (list) => PageView(children: [list]),
    );

    await tester.drag(find.byKey(listKey), const Offset(0, -400));
    await tester.pump();

    expect(controller.visibility, lessThan(1));
  });

  testWidgets('a list nested in another vertical list is ignored', (
    tester,
  ) async {
    final controller = await pumpScrollBody(
      tester,
      (list) => ListView(children: [SizedBox(height: 400, child: list)]),
    );

    await tester.drag(find.byKey(listKey), const Offset(0, -200));
    await tester.pump();

    expect(controller.visibility, 1);
  });
}
