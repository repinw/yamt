import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/diary_scroll_controller.dart';

void main() {
  testWidgets('updates shortcut visibility at top and bottom', (tester) async {
    final controller = DiaryScrollController();
    addTearDown(controller.dispose);

    await _pumpScrollableList(
      tester,
      controller: controller,
      childCount: 30,
    );

    expect(
      controller.scrollController.position.maxScrollExtent,
      greaterThan(0),
    );
    expect(controller.showJumpToMeals, isTrue);
    expect(controller.showScrollToTop, isFalse);

    controller.scrollController.jumpTo(
      controller.scrollController.position.maxScrollExtent,
    );
    await tester.pump();

    expect(controller.showJumpToMeals, isFalse);
    expect(controller.showScrollToTop, isTrue);
  });

  testWidgets('keeps shortcuts hidden when list cannot scroll', (tester) async {
    final controller = DiaryScrollController();
    addTearDown(controller.dispose);

    await _pumpScrollableList(
      tester,
      controller: controller,
      childCount: 1,
    );

    expect(controller.scrollController.position.maxScrollExtent, 0);
    expect(controller.showJumpToMeals, isFalse);
    expect(controller.showScrollToTop, isFalse);
  });
}

Future<void> _pumpScrollableList(
  WidgetTester tester, {
  required DiaryScrollController controller,
  required int childCount,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: ListView.builder(
            controller: controller.scrollController,
            itemCount: childCount,
            itemBuilder: (context, index) {
              return SizedBox(
                height: 64,
                child: Text('Row $index'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
