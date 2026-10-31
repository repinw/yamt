import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_plan_color_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_plan_color_tile/settings_plan_color_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_plan_color_tile/settings_plan_color_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

const _planKey = 'app_plan_color_v1';

/// Builds the app theme from the plan color controller, like `lib/app.dart`.
Future<void> _pumpTile(WidgetTester tester, MemoryAppPreferences preferences) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light(
            plan: ref.watch(appPlanColorControllerProvider),
          ),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsPlanColorTile()),
        ),
      ),
    ),
  );
}

Color _themePlan(WidgetTester tester) =>
    FoodLabelColors.of(tester.element(find.byType(SettingsPlanColorTile))).plan;

void main() {
  testWidgets('the row says Standard without a picked color', (tester) async {
    await _pumpTile(tester, MemoryAppPreferences());

    expect(
      find.descendant(
        of: find.byKey(SettingsPageKeys.planColorTile),
        matching: find.text('Standard'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('moving a slider recolors the app and saves the color', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    await _pumpTile(tester, preferences);

    await tester.tap(find.byKey(SettingsPageKeys.planColorTile));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(AppColorPicker.hueKey), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPlanColorSheet), findsOneWidget);
    final saved = preferences.getIntSync(_planKey);
    expect(saved, isNotNull);
    expect(saved, isNot(FoodLabelColors.light.plan.toARGB32()));
    expect(_themePlan(tester), Color(saved!));
    expect(
      find.descendant(
        of: find.byKey(SettingsPageKeys.planColorTile),
        matching: find.text('Eigene'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reset brings back the default brown', (tester) async {
    final preferences = MemoryAppPreferences(
      initialInts: {_planKey: 0xFF2E7D32},
    );
    await _pumpTile(tester, preferences);
    expect(_themePlan(tester), const Color(0xFF2E7D32));

    await tester.tap(find.byKey(SettingsPageKeys.planColorTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPlanColorSheet.resetKey));
    await tester.pumpAndSettle();

    expect(_themePlan(tester), FoodLabelColors.light.plan);
    expect(preferences.getIntSync(_planKey), isNull);
    final preview = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(SettingsPlanColorSheet.previewKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (preview.decoration as BoxDecoration).color,
      FoodLabelColors.light.plan,
    );
  });
}
