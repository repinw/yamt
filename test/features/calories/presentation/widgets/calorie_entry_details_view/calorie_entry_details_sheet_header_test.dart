import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_header.dart';

void main() {
  testWidgets('renders title and fires close callback', (tester) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieEntryDetailsSheetHeader(
            title: 'Details',
            closeTooltip: 'Close details',
            isSaving: false,
            onClose: () => closeCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Close details'));
    await tester.pump();

    expect(find.text('Details'), findsOneWidget);
    expect(closeCount, 1);
  });

  testWidgets('disables close callback while saving', (tester) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieEntryDetailsSheetHeader(
            title: 'Details',
            closeTooltip: 'Close details',
            isSaving: true,
            onClose: () => closeCount += 1,
          ),
        ),
      ),
    );

    final closeButton = tester.widget<IconButton>(find.byType(IconButton));

    expect(closeButton.onPressed, isNull);
    expect(closeCount, 0);
  });
}
