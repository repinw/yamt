import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('HomePage shows localized title in app bar and body', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        ),
      ),
    );

    expect(find.text('Home'), findsNWidgets(2));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
