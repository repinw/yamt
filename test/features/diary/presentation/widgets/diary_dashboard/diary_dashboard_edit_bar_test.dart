import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_edit_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('"Fertig" is ink, not the accent, in the $name theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
            authStateChangesProvider.overrideWithValue(const AsyncData(null)),
          ],
          child: MaterialApp(
            theme: theme,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DiaryDashboardEditBar(tiles: [])),
          ),
        ),
      );

      final colorScheme = theme.colorScheme;
      final button = tester.widget<Material>(
        find.descendant(
          of: find.byKey(DiaryDashboardKeys.done),
          matching: find.byType(Material),
        ),
      );
      expect(button.color, isNot(colorScheme.primary));
      expect(button.color, colorScheme.onSurface);
      expect(button.textStyle?.color, colorScheme.surface);
      // The shape stays the one of every filled button.
      expect(
        button.shape,
        theme.filledButtonTheme.style?.shape?.resolve(const {}),
      );
    });
  }
}
