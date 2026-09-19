import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_chrome.dart';

void main() {
  Future<void> pumpChrome(
    WidgetTester tester, {
    List<Widget> children = const [Text('Body content')],
    VoidCallback? onClose,
  }) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CalorieEntryDetailsSheetChrome(
          isSaving: false,
          onClose: onClose ?? () {},
          footer: const Text('Footer content'),
          children: children,
        ),
      ),
    );
  }

  testWidgets('renders body and footer and caps the sheet height', (
    tester,
  ) async {
    await pumpChrome(tester);

    final sheetBox = tester.widget<ConstrainedBox>(
      find.byWidgetPredicate((widget) {
        return widget is ConstrainedBox &&
            widget.constraints.maxWidth == 460 &&
            widget.constraints.maxHeight == 540;
      }),
    );

    expect(sheetBox.constraints.maxHeight, 540);
    expect(find.text('Body content'), findsOneWidget);
    expect(find.text('Footer content'), findsOneWidget);
  });

  testWidgets('sizes the sheet to short content', (tester) async {
    await pumpChrome(tester);

    final sheetHeight = tester.getSize(find.byType(DecoratedBox).first).height;

    expect(sheetHeight, lessThan(300));
  });

  testWidgets('closes on a tap outside the sheet, not inside', (tester) async {
    var closeCount = 0;
    await pumpChrome(tester, onClose: () => closeCount += 1);

    await tester.tap(find.text('Body content'));
    await tester.pump();
    expect(closeCount, 0);

    await tester.tapAt(const Offset(200, 40));
    await tester.pump();
    expect(closeCount, 1);
  });
}
