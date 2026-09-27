import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

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
}
