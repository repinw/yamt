import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/widgets/account_status_snackbar.dart';

void main() {
  testWidgets('shows success styled snackbar', (tester) async {
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showAccountStatusSnackBar(context, message: 'Linked');
    await tester.pump();

    expect(find.text('Linked'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('replaces current snackbar and shows error style', (
    tester,
  ) async {
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showAccountStatusSnackBar(context, message: 'First');
    await tester.pump();
    showAccountStatusSnackBar(
      context,
      message: 'Error happened',
      isError: true,
    );
    await tester.pump();

    expect(find.text('First'), findsNothing);
    expect(find.text('Error happened'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
