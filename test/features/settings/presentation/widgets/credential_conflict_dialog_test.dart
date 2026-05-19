import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/presentation/widgets/credential_conflict_dialog/credential_conflict_dialog.dart';

Widget _dialogUnderTest({
  required VoidCallback onCancel,
  required VoidCallback onOverwrite,
  required VoidCallback onDeleteGuestAndContinue,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CredentialConflictDialog(
        title: 'Google account already in use',
        description: 'Choose what should happen next.',
        overwriteAction: 'Overwrite with this guest',
        overwriteSubtitle: 'Keep this guest and replace old account.',
        deleteGuestAction: 'Delete guest and sign in',
        deleteGuestSubtitle: 'Use the existing Google account.',
        cancelLabel: 'Cancel',
        onCancel: onCancel,
        onOverwrite: onOverwrite,
        onDeleteGuestAndContinue: onDeleteGuestAndContinue,
      ),
    ),
  );
}

void main() {
  testWidgets('renders title, description and actions', (tester) async {
    await tester.pumpWidget(
      _dialogUnderTest(
        onCancel: () {},
        onOverwrite: () {},
        onDeleteGuestAndContinue: () {},
      ),
    );

    expect(find.text('Google account already in use'), findsOneWidget);
    expect(find.text('Choose what should happen next.'), findsOneWidget);
    expect(find.text('Overwrite with this guest'), findsOneWidget);
    expect(
      find.text('Keep this guest and replace old account.'),
      findsOneWidget,
    );
    expect(find.text('Delete guest and sign in'), findsOneWidget);
    expect(find.text('Use the existing Google account.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('invokes overwrite callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      _dialogUnderTest(
        onCancel: () {},
        onOverwrite: () => called = true,
        onDeleteGuestAndContinue: () {},
      ),
    );

    await tester.tap(find.text('Overwrite with this guest'));
    expect(called, isTrue);
  });

  testWidgets('invokes delete guest callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      _dialogUnderTest(
        onCancel: () {},
        onOverwrite: () {},
        onDeleteGuestAndContinue: () => called = true,
      ),
    );

    await tester.tap(find.text('Delete guest and sign in'));
    expect(called, isTrue);
  });

  testWidgets('invokes cancel callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      _dialogUnderTest(
        onCancel: () => called = true,
        onOverwrite: () {},
        onDeleteGuestAndContinue: () {},
      ),
    );

    await tester.tap(find.text('Cancel'));
    expect(called, isTrue);
  });
}
