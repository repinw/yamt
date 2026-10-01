import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/settings/presentation/pages/account_page.dart';
import 'package:yamt/features/settings/presentation/widgets/account_guest_card/account_guest_card_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/link_email_password_dialog/link_email_password_dialog.dart';
import 'package:yamt/features/settings/presentation/widgets/link_email_password_dialog/link_email_password_dialog_keys.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User;

Future<void> _pumpGuestAccountPage(WidgetTester tester) async {
  final guest = _MockUser();
  when(() => guest.isAnonymous).thenReturn(true);
  when(() => guest.displayName).thenReturn(null);
  when(() => guest.email).thenReturn(null);
  when(() => guest.uid).thenReturn('guest-uid');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(guest),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a guest opens the email link dialog and fills the fields', (
    tester,
  ) async {
    await _pumpGuestAccountPage(tester);

    final linkButton = find.byKey(AccountGuestCardKeys.linkEmailPasswordButton);
    await tester.ensureVisible(linkButton);
    await tester.pumpAndSettle();
    await tester.tap(linkButton);
    await tester.pumpAndSettle();

    expect(find.byType(LinkEmailPasswordDialog), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AuthEmailField),
        matching: find.byType(TextFormField),
      ),
      'guest@example.com',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AuthPasswordField).first,
        matching: find.byType(TextFormField),
      ),
      'secret123',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AuthPasswordField).last,
        matching: find.byType(TextFormField),
      ),
      'different123',
    );
    await tester.tap(find.byKey(LinkEmailPasswordDialogKeys.confirmButton));
    await tester.pumpAndSettle();

    // The mismatched confirmation keeps the dialog open without a submit.
    expect(find.byType(LinkEmailPasswordDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
