import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_join_name_dialog/household_join_name_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Widget buildTestApp({required void Function(String?) onResult}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showHouseholdJoinNameDialog(
                    context: context,
                    l10n: AppLocalizations.of(context)!,
                  );
                  onResult(result);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('shows validation error when submitted empty', (tester) async {
    String? result;
    await tester.pumpWidget(buildTestApp(onResult: (val) => result = val));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(
      find.text(
        'Please enter your name so other household members can recognize you.',
      ),
      findsOneWidget,
    );

    // Tap submit button while empty
    await tester.tap(find.text('Save & Join'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('returns trimmed name when submitted with valid text', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(buildTestApp(onResult: (val) => result = val));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '  Alex  ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save & Join'));
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdJoinNameDialog), findsNothing);
    expect(result, 'Alex');
  });

  testWidgets('returns null when canceled', (tester) async {
    String? result;
    await tester.pumpWidget(buildTestApp(onResult: (val) => result = val));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdJoinNameDialog), findsNothing);
    expect(result, isNull);
  });
}
