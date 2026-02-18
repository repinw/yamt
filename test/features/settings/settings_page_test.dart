import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/settings_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('SettingsPage renders localized rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsPage()),
      ),
    );

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose app language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Manage profile and sign-in'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
  });
}
