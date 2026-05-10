import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_chrome.dart';

void main() {
  testWidgets('renders header body footer and constrains sheet height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CalorieEntryDetailsSheetChrome(
          title: 'Details',
          isSaving: false,
          onClose: () {},
          footer: const Text('Footer content'),
          child: const Text('Body content'),
        ),
      ),
    );

    final sheetBox = tester.widget<ConstrainedBox>(
      find.byWidgetPredicate((widget) {
        return widget is ConstrainedBox &&
            widget.constraints.maxWidth == 460 &&
            widget.constraints.maxHeight == 540;
      }),
    );

    expect(sheetBox.constraints.maxWidth, 460);
    expect(sheetBox.constraints.maxHeight, 540);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Body content'), findsOneWidget);
    expect(find.text('Footer content'), findsOneWidget);
  });
}
