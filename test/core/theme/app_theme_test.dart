import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/intro_accent_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

const _filledKey = Key('filled');
const _tonalKey = Key('tonal');
const _outlinedKey = Key('outlined');
const _textKey = Key('text');

Future<void> _pumpButtons(WidgetTester tester, ThemeData theme) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Column(
          children: [
            FilledButton(
              key: _filledKey,
              onPressed: () {},
              child: const Text('Eintragen'),
            ),
            FilledButton.tonal(
              key: _tonalKey,
              onPressed: () {},
              child: const Text('In Vorrat'),
            ),
            OutlinedButton(
              key: _outlinedKey,
              onPressed: () {},
              child: const Text('Abbrechen'),
            ),
            TextButton(
              key: _textKey,
              onPressed: () {},
              child: const Text('Details'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Distance between the hues of [a] and [b] on the color wheel, 0 to 180.
double _hueDistance(Color a, Color b) {
  final d = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
}

Material _buttonMaterial(WidgetTester tester, Key key) {
  return tester.widget<Material>(
    find.descendant(of: find.byKey(key), matching: find.byType(Material)),
  );
}

void main() {
  for (final (name, theme, colors) in [
    ('light', AppTheme.light(), FoodLabelColors.light),
    ('dark', AppTheme.dark(), FoodLabelColors.dark),
  ]) {
    group('AppTheme.$name', () {
      test('sets all text in Plus Jakarta Sans', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.sans);
        expect(theme.textTheme.titleLarge?.fontFamily, AppFonts.sans);
        expect(theme.textTheme.labelLarge?.fontFamily, AppFonts.sans);
      });

      test('separates titles, actions and text by weight', () {
        final textTheme = ThemeData.localize(
          theme,
          Typography.englishLike2021,
        ).textTheme;
        expect(textTheme.headlineSmall?.fontWeight, FontWeight.w800);
        expect(textTheme.titleLarge?.fontWeight, FontWeight.w800);
        expect(textTheme.labelLarge?.fontWeight, FontWeight.w700);
        expect(textTheme.bodyMedium?.fontWeight, FontWeight.w400);
      });

      testWidgets('fills only the main button with lime', (tester) async {
        await _pumpButtons(tester, theme);

        final filled = _buttonMaterial(tester, _filledKey);
        expect(filled.color, colors.accent);
        expect(filled.textStyle?.color, colors.onAccent);

        final tonal = _buttonMaterial(tester, _tonalKey);
        expect(tonal.color, theme.colorScheme.secondaryContainer);
        expect(tonal.textStyle?.color, colors.ink);
      });

      test('keeps tonal buttons apart from the page, cards and sheets', () {
        final tonal = theme.colorScheme.secondaryContainer;
        expect(tonal, isNot(colors.paper));
        expect(tonal, isNot(colors.card));
        expect(tonal, isNot(colors.accent));
        expect(theme.bottomSheetTheme.backgroundColor, colors.card);
        expect(theme.dialogTheme.backgroundColor, colors.card);
      });

      testWidgets('draws no frame around an outlined button', (tester) async {
        await _pumpButtons(tester, theme);

        final outlined = _buttonMaterial(tester, _outlinedKey);
        expect(outlined.color, theme.colorScheme.secondaryContainer);
        final shape = outlined.shape! as RoundedRectangleBorder;
        expect(shape.side, BorderSide.none);
      });

      testWidgets('rounds buttons with the control radius', (tester) async {
        await _pumpButtons(tester, theme);

        for (final key in [_filledKey, _tonalKey, _outlinedKey, _textKey]) {
          final shape =
              _buttonMaterial(tester, key).shape! as RoundedRectangleBorder;
          expect(
            shape.borderRadius,
            const BorderRadius.all(Radius.circular(AppRadius.md)),
          );
        }
      });

      testWidgets('shows a quiet action as underlined ink text', (
        tester,
      ) async {
        await _pumpButtons(tester, theme);

        final text = _buttonMaterial(tester, _textKey);
        expect(text.textStyle?.color, colors.ink);
        expect(text.textStyle?.decoration, TextDecoration.underline);
      });

      test('draws switches in ink instead of lime', () {
        final track = theme.switchTheme.trackColor?.resolve({
          WidgetState.selected,
        });
        expect(track, colors.ink);
      });
    });
  }

  for (final accent in AppAccent.values) {
    for (final (name, theme, tones, paper) in [
      (
        'light',
        AppTheme.light(accent: accent),
        accent.light,
        FoodLabelColors.light.paper,
      ),
      (
        'dark',
        AppTheme.dark(accent: accent),
        accent.dark,
        FoodLabelColors.dark.paper,
      ),
    ]) {
      group('AppTheme.$name with ${accent.name}', () {
        final colors = theme.extension<FoodLabelColors>()!;

        test('fills with the accent and writes accent text', () {
          expect(theme.colorScheme.primary, tones.fill);
          expect(colors.accent, tones.fill);
          expect(theme.colorScheme.secondary, tones.text);
          expect(colors.accentText, tones.text);
          expect(theme.colorScheme.primaryContainer, tones.container);
        });

        test('keeps text on the accent and accent text readable', () {
          expect(
            contrastRatio(colors.onAccent, tones.fill),
            greaterThanOrEqualTo(4.5),
          );
          expect(contrastRatio(tones.text, paper), greaterThanOrEqualTo(4.5));
        });

        test('keeps accent text apart from the "over the goal" red', () {
          expect(
            _hueDistance(tones.text, theme.colorScheme.error),
            greaterThanOrEqualTo(30),
          );
        });

        test('keeps the data colors of the lime theme', () {
          final lime = (name == 'light' ? AppTheme.light() : AppTheme.dark())
              .extension<MetricAccentColors>()!;
          final metrics = theme.extension<MetricAccentColors>()!;
          expect(metrics.protein, lime.protein);
          expect(metrics.carbs, lime.carbs);
          expect(metrics.fat, lime.fat);
          expect(metrics.weight, lime.weight);
          expect(metrics.activity, lime.activity);
          expect(metrics.steps, lime.steps);
          expect(metrics.today, tones.fill);
        });

        test('keeps the onboarding chapter colors of the lime theme', () {
          final lime = IntroAccentColors.fromColorScheme(
            (name == 'light' ? AppTheme.light() : AppTheme.dark()).colorScheme,
          );
          final intro = IntroAccentColors.fromColorScheme(theme.colorScheme);
          expect(intro.amber, lime.amber);
          expect(intro.cyan, lime.cyan);
          expect(intro.rose, lime.rose);
        });
      });
    }
  }

  test('lime keeps the Graphit accent of the food label colors', () {
    for (final (theme, colors) in [
      (AppTheme.light(), FoodLabelColors.light),
      (AppTheme.dark(), FoodLabelColors.dark),
    ]) {
      final themed = theme.extension<FoodLabelColors>()!;
      expect(themed.accent, colors.accent);
      expect(themed.onAccent, colors.onAccent);
      expect(themed.accentText, colors.accentText);
      expect(themed.onTile, colors.onTile);
    }
  });

  test('keeps the Graphit plan brown', () {
    expect(
      AppTheme.light().extension<FoodLabelColors>()!.plan,
      FoodLabelColors.light.plan,
    );
    expect(
      AppTheme.dark().extension<FoodLabelColors>()!.plan,
      FoodLabelColors.dark.plan,
    );
  });

  group('custom', () {
    test('a copy of the light design keeps its colors', () {
      final light = AppTheme.light();
      final custom = AppTheme.custom(AppCustomColors.copyOf(light));
      final labels = custom.extension<FoodLabelColors>()!;
      final metrics = custom.extension<MetricAccentColors>()!;

      expect(custom.brightness, Brightness.light);
      expect(labels.paper, FoodLabelColors.light.paper);
      expect(labels.ink, FoodLabelColors.light.ink);
      expect(labels.plan, FoodLabelColors.light.plan);
      expect(custom.colorScheme.primary, light.colorScheme.primary);
      expect(custom.colorScheme.error, light.colorScheme.error);
      expect(metrics.protein, light.extension<MetricAccentColors>()!.protein);
      expect(metrics.macrosAsPicked, isTrue);
      expect(metrics.allMacrosColored, isFalse);
    });

    test('every picked color reaches the theme', () {
      const picked = Color(0xFF2E7D32);
      final base = AppCustomColors.copyOf(AppTheme.dark());
      for (final key in AppCustomColor.values) {
        final theme = AppTheme.custom(base.withColor(key, picked));
        final labels = theme.extension<FoodLabelColors>()!;
        final metrics = theme.extension<MetricAccentColors>()!;
        final actual = switch (key) {
          AppCustomColor.paper => theme.colorScheme.surface,
          AppCustomColor.card => labels.card,
          AppCustomColor.ink => theme.colorScheme.onSurface,
          AppCustomColor.muted => theme.colorScheme.onSurfaceVariant,
          AppCustomColor.lines => theme.colorScheme.outlineVariant,
          AppCustomColor.accent => theme.colorScheme.primary,
          AppCustomColor.plan => labels.plan,
          AppCustomColor.protein => metrics.protein,
          AppCustomColor.carbs => metrics.carbs,
          AppCustomColor.fat => metrics.fat,
          AppCustomColor.signal => theme.colorScheme.error,
        };
        expect(actual, picked, reason: key.name);
        expect(theme.brightness, Brightness.dark);
      }
    });

    test('snack bars take the text color with paper as text', () {
      final colors = AppCustomColors.copyOf(AppTheme.light());
      final scheme = AppTheme.custom(colors).colorScheme;

      expect(scheme.inverseSurface, colors[AppCustomColor.ink]);
      expect(scheme.onInverseSurface, colors[AppCustomColor.paper]);
    });

    test('carries "Makros immer bunt" to the metric colors', () {
      final colors = AppCustomColors.copyOf(AppTheme.light());

      expect(
        AppTheme.custom(colors)
            .withAllMacrosColored(value: true)
            .extension<MetricAccentColors>()!
            .allMacrosColored,
        isTrue,
      );
    });
  });
}
