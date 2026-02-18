import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/home/home_tab_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap(HomeTabType tab) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeTabPage(tab: tab)),
  );
}

void main() {
  testWidgets('HomeTabPage renders settings tab title', (tester) async {
    await tester.pumpWidget(_wrap(HomeTabType.settings));

    expect(find.text('Settings'), findsOneWidget);
  });
}
