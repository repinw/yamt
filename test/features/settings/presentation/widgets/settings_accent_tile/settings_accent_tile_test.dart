import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

/// Builds the app theme from the accent controller, like `lib/app.dart`.
Future<void> _pumpTile(WidgetTester tester, MemoryAppPreferences preferences) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light(accent: ref.watch(appAccentControllerProvider)),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsAccentTile()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the current accent in the row', (tester) async {
    await _pumpTile(
      tester,
      MemoryAppPreferences(initialStrings: {'app_accent_v1': 'cyan'}),
    );

    expect(
      find.descendant(
        of: find.byKey(SettingsPageKeys.accentTile),
        matching: find.text('Cyan'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a swatch recolors the app, saves, and keeps the sheet open', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    await _pumpTile(tester, preferences);

    await tester.tap(find.byKey(SettingsPageKeys.accentTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsAccentSheet.swatchKey(AppAccent.pink)));
    await tester.pumpAndSettle();

    final sheet = find.byType(SettingsAccentSheet);
    expect(sheet, findsOneWidget);
    expect(
      Theme.of(tester.element(sheet)).colorScheme.primary,
      AppAccent.pink.light.fill,
    );
    expect(preferences.getStringSync('app_accent_v1'), 'pink');
    expect(
      tester.getSemantics(
        find.byKey(SettingsAccentSheet.swatchKey(AppAccent.pink)),
      ),
      isSemantics(label: 'Pink', isButton: true, isSelected: true),
    );
  });
}
