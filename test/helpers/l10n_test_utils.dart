import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<AppLocalizations> pumpLocalizations(
  WidgetTester tester, {
  required Locale locale,
}) async {
  AppLocalizations? localizations;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
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
