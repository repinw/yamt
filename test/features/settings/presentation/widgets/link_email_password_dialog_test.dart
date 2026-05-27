import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/presentation/widgets/link_email_password_dialog/link_email_password_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _dialogUnderTest({
  required Future<void> Function({
    required String email,
    required String password,
  })
  onSubmitCredentials,
  required String Function(Object error) errorMessageFor,
  bool Function(Object error)? shouldBubbleSubmitError,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return LinkEmailPasswordDialog(
            l10n: l10n,
            onSubmitCredentials: onSubmitCredentials,
            errorMessageFor: errorMessageFor,
            shouldBubbleSubmitError: shouldBubbleSubmitError,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders dialog title and description', (tester) async {
    await tester.pumpWidget(
      _dialogUnderTest(
        onSubmitCredentials: ({required email, required password}) async {},
        errorMessageFor: (error) => 'Error',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link guest account'), findsOneWidget);
    expect(
      find.text(
        'Create email sign-in credentials for this guest account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'fails form validation and does not submit if fields are empty',
    (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        _dialogUnderTest(
          onSubmitCredentials: ({required email, required password}) async {
            submitted = true;
          },
          errorMessageFor: (error) => 'Error',
        ),
      );
      await tester.pumpAndSettle();

      final submitButtonFinder = find.byType(FilledButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('The field is required'), findsNWidgets(3));
    },
  );

  testWidgets('submits successfully when fields are filled', (tester) async {
    var submittedEmail = '';
    var submittedPassword = '';

    await tester.pumpWidget(
      _dialogUnderTest(
        onSubmitCredentials: ({required email, required password}) async {
          submittedEmail = email;
          submittedPassword = password;
        },
        errorMessageFor: (error) => 'Error',
      ),
    );
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );

    // Enter password
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'password123',
    );

    // Enter confirm password
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'password123',
    );

    await tester.pumpAndSettle();

    final submitButtonFinder = find.byType(FilledButton);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    expect(submittedEmail, 'test@example.com');
    expect(submittedPassword, 'password123');
  });

  testWidgets(
    'handles submission error and displays formatted error message',
    (tester) async {
      final customError = Exception('Custom Error');

      await tester.pumpWidget(
        _dialogUnderTest(
          onSubmitCredentials: ({required email, required password}) async {
            throw customError;
          },
          errorMessageFor: (error) => 'Formatted: $error',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );
      await tester.pumpAndSettle();

      final submitButtonFinder = find.byType(FilledButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Formatted: Exception: Custom Error'), findsOneWidget);
    },
  );

  testWidgets(
    'bubbles up submission error when shouldBubbleSubmitError returns true',
    (tester) async {
      final customError = Exception('Custom Error');
      Object? poppedValue;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final l10n = AppLocalizations.of(context)!;
                    poppedValue = await showDialog(
                      context: context,
                      builder: (context) => LinkEmailPasswordDialog(
                        l10n: l10n,
                        onSubmitCredentials:
                            ({required email, required password}) async {
                              throw customError;
                            },
                        errorMessageFor: (error) => 'Error',
                        shouldBubbleSubmitError: (error) => true,
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );
      await tester.pumpAndSettle();

      final submitButtonFinder = find.byType(FilledButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      expect(poppedValue, same(customError));
      expect(find.byType(LinkEmailPasswordDialog), findsNothing);
    },
  );
}
