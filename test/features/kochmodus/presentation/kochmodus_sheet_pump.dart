import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';

/// Key of the button that opens the sheet under test.
const sheetOpenKey = ValueKey<String>('sheet-test-open');

/// Opens a sheet from a button and keeps what it returned in [results].
///
/// The app has the Vorrat's saved settings in [preferences] (the picker
/// reads them). [width], [height], [keyboard] and [textScale] set up the
/// small phone with an open keyboard and big text.
Future<void> pumpSheet<T extends Object>(
  WidgetTester tester,
  Future<T?> Function(BuildContext context) show,
  List<T?> results, {
  MemoryAppPreferences? preferences,
  Locale locale = const Locale('en'),
  double width = 800,
  double height = 1200,
  double keyboard = 0,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: sheetOpenKey,
              onPressed: () async => results.add(await show(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(sheetOpenKey));
  await tester.pumpAndSettle();
}

/// Taps the widget with [key] and settles.
Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// The texts of the app in the locale of the test.
AppLocalizations sheetL10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byKey(sheetOpenKey)))!;
