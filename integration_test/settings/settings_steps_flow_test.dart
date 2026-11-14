import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/app_themes.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_menu.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/health/support/fake_health_steps_service.dart';
import '../../test/helpers/memory_app_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the steps switch shows the steps card, its menu sets a goal and hides it',
    (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(settingsRepository.dispose);
      final steps = FakeHealthStepsService();

      // The steps card sits under the settings page, as the diary shows it
      // under the budget card.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 15, 12)),
            authStateChangesProvider.overrideWithValue(
              const AsyncData<User?>(null),
            ),
            appVersionProvider.overrideWithValue(const AsyncData('3.10.0+43')),
            calorieSettingsRepositoryProvider.overrideWithValue(
              settingsRepository,
            ),
            healthConnectionServiceProvider.overrideWithValue(
              FakeHealthConnectionService(
                const HealthConnectionStatus(
                  platform: HealthPlatform.android,
                  healthConnectAvailability:
                      HealthConnectAvailability.available,
                  permissionState: HealthPermissionState.granted,
                  historyAccess: HealthHistoryAccess.granted,
                ),
              ),
            ),
            healthStepsServiceProvider.overrideWithValue(steps),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final themes = ref.watch(appThemesProvider);
              return MaterialApp(
                theme: themes.light,
                darkTheme: themes.dark,
                themeMode: themes.mode,
                locale: const Locale('de'),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Column(
                    children: [
                      const Expanded(child: SettingsPage()),
                      DiaryStepsCard(
                        day: DateTime(2026, 6, 15),
                        weekStart: null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(SettingsPageKeys.stepsTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(SettingsPageKeys.stepsTile));
      await tester.pumpAndSettle();

      expect(steps.accessRequests, 1);
      String cardText() => tester
          .widget<Text>(find.byKey(DiaryStepsCard.valueKey))
          .textSpan!
          .toPlainText();
      expect(cardText(), '8.432 Schritte');

      // A tap on the card opens its menu; a goal names itself on the card.
      await tester.tap(find.byKey(DiaryStepsCard.cardKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DiaryStepsCardMenu.presetKey(10000)));
      await tester.pumpAndSettle();
      expect(cardText(), '8.432 / 10.000');
      expect(find.byKey(DiaryStepsCard.goalLineKey), findsOneWidget);

      // The menu's switch takes the steps out again, here and in the settings.
      await tester.tap(find.byKey(DiaryStepsCardMenu.showSwitchKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryStepsCard.cardKey), findsNothing);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(SettingsPageKeys.stepsTile),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
    },
  );
}
