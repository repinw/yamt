import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_themes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/features/settings/presentation/settings_custom_colors_page.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_base_dialog.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_panel.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_strip.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_colors_preview.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';

final _start = AppCustomColors.copyOf(AppTheme.light());

Future<MemoryAppPreferences> _pumpPage(
  WidgetTester tester, {
  // A phone screen.
  Size physicalSize = const Size(1080, 2340),
  double devicePixelRatio = 2.75,
  String? recentColors,
}) async {
  tester.view
    ..physicalSize = physicalSize
    ..devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  final preferences = MemoryAppPreferences(
    initialStrings: {
      'app_theme_mode_v1': 'custom',
      'app_custom_colors_v1': jsonEncode(_start.toJson()),
      'app_recent_colors_v1': ?recentColors,
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
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
            home: const SettingsCustomColorsPage(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

AppCustomColors _saved(MemoryAppPreferences preferences) =>
    AppCustomColors.fromJson(
      jsonDecode(preferences.getStringSync('app_custom_colors_v1')!)
          as Map<String, Object?>,
    );

void main() {
  testWidgets('a picked color shows live across the app, the editor too, '
      'and is saved when taken', (tester) async {
    final preferences = await _pumpPage(tester);
    final paper = find.byKey(
      SettingsCustomColorStrip.swatchKey(AppCustomColor.paper),
    );
    await tester.ensureVisible(paper);
    await tester.pumpAndSettle();
    await tester.tap(paper);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsCustomColorPanel), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byKey(AppColorPicker.wheelKey)) +
          const Offset(60, 40),
    );
    await tester.drag(
      find.byKey(AppColorPicker.valueKey),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    final live = Theme.of(tester.element(find.byType(Scaffold)))
        .colorScheme
        .surface;
    expect(live, isNot(_start[AppCustomColor.paper]));
    expect(_saved(preferences), _start);

    await tester.tap(find.byKey(SettingsCustomColorPanel.applyKey));
    await tester.pumpAndSettle();

    final saved = _saved(preferences)[AppCustomColor.paper];
    expect(saved, live);
    expect(
      FoodLabelColors.of(
        tester.element(find.byKey(SettingsCustomColorsPreview.previewKey)),
      ).paper,
      saved,
    );
  });

  testWidgets('another color keeps the one picked, cancel drops it, and undo '
      'takes saved steps back', (tester) async {
    final preferences = await _pumpPage(tester);
    Future<void> open(AppCustomColor key) async {
      final swatch = find.byKey(SettingsCustomColorStrip.swatchKey(key));
      await tester.ensureVisible(swatch);
      await tester.pumpAndSettle();
      await tester.tap(swatch);
      await tester.pumpAndSettle();
    }

    Future<void> drag(Offset offset) async {
      await tester.tapAt(
        tester.getCenter(find.byKey(AppColorPicker.wheelKey)) + offset,
      );
      await tester.pumpAndSettle();
    }

    MetricAccentColors shown() =>
        Theme.of(tester.element(find.byType(Scaffold)))
            .extension<MetricAccentColors>()!;

    await open(AppCustomColor.fat);
    await drag(const Offset(40, 40));
    final fat = shown().fat;
    expect(fat, isNot(_start[AppCustomColor.fat]));

    // A tap on another part of the preview keeps fat.
    await tester.tap(find.text('Proteinriegel'));
    await tester.pumpAndSettle();
    expect(_saved(preferences)[AppCustomColor.fat], fat);

    await drag(const Offset(-40, 40));
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(
      FoodLabelColors.of(
        tester.element(find.byKey(SettingsCustomColorsPreview.previewKey)),
      ).plan,
      _start[AppCustomColor.plan],
    );
    expect(_saved(preferences)[AppCustomColor.fat], fat);

    final undo = find.byKey(SettingsCustomColorsPage.undoKey);
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(_saved(preferences), _start);
    expect(shown().fat, _start[AppCustomColor.fat]);
    expect(tester.widget<IconButton>(undo).onPressed, isNull);
  });

  testWidgets('"Makros immer bunt" and reset', (tester) async {
    final preferences = await _pumpPage(tester);

    final allMacros = find.byKey(SettingsCustomColorsPage.allMacrosKey);
    await tester.ensureVisible(allMacros);
    await tester.pumpAndSettle();
    await tester.tap(allMacros);
    await tester.pumpAndSettle();
    expect(preferences.getStringSync('app_all_macros_colored_v1'), '1');
    expect(
      MetricAccentColors.of(
        tester.element(find.byKey(SettingsCustomColorsPreview.previewKey)),
      ).allMacrosColored,
      isTrue,
    );

    await tester.tap(
      find.byKey(SettingsCustomColorStrip.swatchKey(AppCustomColor.protein)),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(AppColorPicker.wheelKey)) +
          const Offset(-60, 40),
    );
    await tester.tap(find.byKey(SettingsCustomColorPanel.applyKey));
    await tester.pumpAndSettle();
    expect(
      _saved(preferences)[AppCustomColor.protein],
      isNot(_start[AppCustomColor.protein]),
    );

    await tester.tap(find.byKey(SettingsCustomColorsPage.resetKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(SettingsCustomBaseDialog.optionKey(Brightness.light)),
    );
    await tester.pumpAndSettle();
    expect(_saved(preferences), _start);
  });

  testWidgets('a tap on the preview opens the picker of that part', (
    tester,
  ) async {
    await _pumpPage(tester);
    Future<Color> pickerAfterTapOn(String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
      final color = tester
          .widget<AppColorPicker>(find.byType(AppColorPicker))
          .color;
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      return color;
    }

    expect(
      await pickerAfterTapOn('Proteinriegel'),
      _start[AppCustomColor.plan],
    );
    expect(await pickerAfterTapOn('Scannen'), _start[AppCustomColor.accent]);
    expect(await pickerAfterTapOn('Rückgängig'), _start[AppCustomColor.ink]);
    expect(await pickerAfterTapOn('Curry gebucht'), _start[AppCustomColor.ink]);
  });

  testWidgets('nothing scrolls, also with the largest text on a small phone', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(
      tester,
      physicalSize: const Size(720, 1280),
      devicePixelRatio: 2,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(SettingsCustomColorsPage),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(SettingsCustomColorsPage.allMacrosKey).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('the color panel with six recent colors fits the largest text '
      'on a small phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(
      tester,
      physicalSize: const Size(720, 1280),
      devicePixelRatio: 2,
      recentColors: [for (var i = 1; i <= 6; i++) 0xFF000000 + i * 0x202020]
          .join(','),
    );

    await tester.tap(
      find.byKey(SettingsCustomColorStrip.swatchKey(AppCustomColor.protein)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(SettingsCustomColorPanel.applyKey).hitTestable(),
      findsOneWidget,
    );
  });
}
