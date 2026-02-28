import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<AppLocalizations> pumpLocalizations(
  WidgetTester tester, {
  required Locale locale,
}) async {
  AppLocalizations? localizations;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          localizations = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();

  expect(localizations, isNotNull);
  return localizations!;
}
