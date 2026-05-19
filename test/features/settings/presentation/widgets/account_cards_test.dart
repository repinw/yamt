import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/settings/presentation/widgets/account_guest_card/account_guest_card.dart';
import 'package:yamt/features/settings/presentation/widgets/account_user_info_card/account_user_info_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('AccountGuestCard renders localized content and handles tap', (
    tester,
  ) async {
    var googleTapCount = 0;
    var emailTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return AccountGuestCard(
                l10n: l10n,
                isActionLoading: false,
                onLinkWithGoogle: () => googleTapCount++,
                onLinkWithEmailPassword: () => emailTapCount++,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Guest account'), findsOneWidget);
    expect(find.text('Link with Google'), findsOneWidget);
    expect(find.text('Link with email & password'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Link with Google'));
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Link with email & password'),
    );

    expect(googleTapCount, 1);
    expect(emailTapCount, 1);
  });

  testWidgets('AccountGuestCard disables action while loading', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return AccountGuestCard(
                l10n: l10n,
                isActionLoading: true,
                onLinkWithGoogle: () => tapCount++,
                onLinkWithEmailPassword: () => tapCount++,
              );
            },
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final emailButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(button.onPressed, isNull);
    expect(emailButton.onPressed, isNull);
    expect(tapCount, 0);
  });

  testWidgets('AccountUserInfoCard shows values and fallbacks', (tester) async {
    final user = _MockUser();
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn('');
    when(() => user.uid).thenReturn('guest-123');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return AccountUserInfoCard(user: user, l10n: l10n);
            },
          ),
        ),
      ),
    );

    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.text('guest-123'), findsOneWidget);
  });
}
