import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _gram = ' g';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('de'),
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(brightness: brightness),
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

double _lightness(Color color) => HSLColor.fromColor(color).lightness;

// The colour of the span with [text] inside the one rich line.
Color? _spanColor(WidgetTester tester, String text) {
  Color? found;
  final rich = tester.widget<Text>(find.byType(Text));
  rich.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.text == text) found = span.style?.color;
    return true;
  });
  return found;
}

void main() {
  group('columns', () {
    testWidgets('show whole grams over the labels in this order', (
      tester,
    ) async {
      await _pump(
        tester,
        const MacroGrams.columns(protein: 14.4, carbs: 50.6, fat: 12.4),
      );

      expect(find.text('14$_gram'), findsOneWidget);
      expect(find.text('51$_gram'), findsOneWidget);
      expect(find.text('12$_gram'), findsOneWidget);
      expect(find.text('Eiweiß'), findsOneWidget);
      expect(find.text('Kohlenhydrate'), findsOneWidget);
      expect(find.text('Fett'), findsOneWidget);
      final protein = tester.getTopLeft(find.text('Eiweiß')).dx;
      final carbs = tester.getTopLeft(find.text('Kohlenhydrate')).dx;
      final fat = tester.getTopLeft(find.text('Fett')).dx;
      expect(protein, lessThan(carbs));
      expect(carbs, lessThan(fat));
    });

    testWidgets('keep number and unit together with a no-break space', (
      tester,
    ) async {
      await _pump(
        tester,
        const MacroGrams.columns(protein: 7, carbs: 8, fat: 9),
      );

      expect(find.text('7 g'), findsOneWidget);
      expect(find.text('7 g'), findsNothing);
    });

    testWidgets('colour the numbers darker than the macro on light paper', (
      tester,
    ) async {
      await _pump(
        tester,
        const MacroGrams.columns(protein: 7, carbs: 8, fat: 9),
      );

      final protein = _colorOf(tester, '7$_gram')!;
      final carbs = _colorOf(tester, '8$_gram')!;
      final fat = _colorOf(tester, '9$_gram')!;
      expect(_lightness(protein), lessThanOrEqualTo(0.38 + 0.001));
      expect(_lightness(carbs), lessThanOrEqualTo(0.38 + 0.001));
      expect(_lightness(fat), lessThanOrEqualTo(0.38 + 0.001));
      expect(<Color>{protein, carbs, fat}, hasLength(3));
    });

    testWidgets('lighten the numbers on dark paper', (tester) async {
      await _pump(
        tester,
        const MacroGrams.columns(
          protein: 7,
          carbs: 8,
          fat: 9,
          palette: FoodLabelColors.dark,
        ),
      );

      for (final text in ['7$_gram', '8$_gram', '9$_gram']) {
        expect(
          _lightness(_colorOf(tester, text)!),
          greaterThanOrEqualTo(0.66 - 0.01),
        );
      }
    });

    testWidgets('mute the labels', (tester) async {
      await _pump(
        tester,
        const MacroGrams.columns(protein: 7, carbs: 8, fat: 9),
      );

      for (final label in ['Eiweiß', 'Kohlenhydrate', 'Fett']) {
        expect(_colorOf(tester, label), FoodLabelColors.light.muted);
      }
    });

    testWidgets('mute the labels of the given palette', (tester) async {
      await _pump(
        tester,
        const MacroGrams.columns(
          protein: 7,
          carbs: 8,
          fat: 9,
          palette: FoodLabelColors.dark,
        ),
      );

      expect(_colorOf(tester, 'Eiweiß'), FoodLabelColors.dark.muted);
    });

    testWidgets('read one sentence for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const MacroGrams.columns(protein: 14, carbs: 51, fat: 13),
      );

      expect(
        find.bySemanticsLabel(
          'Eiweiß 14 Gramm, Kohlenhydrate 51 Gramm, Fett 13 Gramm',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('columns, picked colours', () {
    final picked = MetricAccentColors.fromColorScheme(const ColorScheme.light())
        .copyWith(
          protein: const Color(0xFFFFE680),
          carbs: const Color(0xFF80FFE6),
          fat: const Color(0xFFE680FF),
          macrosAsPicked: true,
        );

    testWidgets('keep the picked colours on light paper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [picked]),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MacroGrams.columns(protein: 7, carbs: 8, fat: 9),
          ),
        ),
      );

      expect(_colorOf(tester, '7$_gram'), picked.protein);
      expect(_colorOf(tester, '8$_gram'), picked.carbs);
      expect(_colorOf(tester, '9$_gram'), picked.fat);
    });

    testWidgets('textColors gives the picked colours unchanged', (
      tester,
    ) async {
      late ({Color protein, Color carbs, Color fat}) colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [picked]),
          home: Builder(
            builder: (context) {
              colors = MacroGrams.textColors(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors.protein, picked.protein);
      expect(colors.carbs, picked.carbs);
      expect(colors.fat, picked.fat);
    });
  });

  group('textColors', () {
    late ({Color protein, Color carbs, Color fat}) colors;

    Future<void> read(
      WidgetTester tester, {
      FoodLabelColors? palette,
      Brightness brightness = Brightness.light,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            colors = MacroGrams.textColors(context, palette: palette);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    testWidgets('darken the macros on the light paper of the theme', (
      tester,
    ) async {
      await read(tester);

      for (final color in [colors.protein, colors.carbs, colors.fat]) {
        expect(_lightness(color), lessThanOrEqualTo(0.38 + 0.001));
      }
      expect(<Color>{colors.protein, colors.carbs, colors.fat}, hasLength(3));
    });

    testWidgets('lighten the macros for a dark palette', (tester) async {
      await read(tester, palette: FoodLabelColors.dark);

      for (final color in [colors.protein, colors.carbs, colors.fat]) {
        expect(_lightness(color), greaterThanOrEqualTo(0.66 - 0.01));
      }
    });

    testWidgets('equal what the columns draw', (tester) async {
      await _pump(
        tester,
        const MacroGrams.columns(protein: 7, carbs: 8, fat: 9),
      );
      final context = tester.element(find.byType(MacroGrams));
      final drawn = MacroGrams.textColors(context);

      expect(_colorOf(tester, '7$_gram'), drawn.protein);
      expect(_colorOf(tester, '8$_gram'), drawn.carbs);
      expect(_colorOf(tester, '9$_gram'), drawn.fat);
    });
  });

  group('column label at large text', () {
    for (final locale in [const Locale('de'), const Locale('en')]) {
      testWidgets(
        'is not cut off in a narrow column (${locale.languageCode})',
        (tester) async {
          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = errors.add;
          addTearDown(() => FlutterError.onError = previous);
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: const Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  // Three columns of 88 px and the gaps between them.
                  child: SizedBox(
                    width: 3 * 88 + 2 * 8,
                    child: MacroGrams.columns(protein: 14, carbs: 51, fat: 13),
                  ),
                ),
              ),
            ),
          );

          expect(errors, isEmpty);
          expect(tester.takeException(), isNull);
          final carbs = find.text(
            AppLocalizations.of(tester.element(find.byType(MacroGrams)))!
                .caloriesCarbsLabel,
          );
          expect(carbs, findsOneWidget);
          // The label sits in a FittedBox that scales it down to its column.
          final box = find.ancestor(
            of: carbs,
            matching: find.byType(FittedBox),
          );
          expect(box, findsOneWidget);
          expect(
            tester.getRect(carbs).width,
            lessThanOrEqualTo(tester.getSize(box).width + 0.01),
          );
          expect(tester.getSize(box).width, lessThanOrEqualTo(88 + 0.01));
        },
      );
    }
  });

  group('line', () {
    testWidgets('is one short line with the short carbs label', (tester) async {
      await _pump(
        tester,
        const MacroGrams.line(protein: 14.2, carbs: 50.7, fat: 13.5),
      );

      final rich = tester.widget<Text>(find.byType(Text));
      // Each letter keeps its number with a no-break space.
      expect(
        rich.textSpan!.toPlainText(),
        'P\u00A014 · KH\u00A051 · F\u00A014',
      );
      expect(rich.maxLines, 1);
    });

    testWidgets('says the short carbs label of the language', (tester) async {
      await _pump(
        tester,
        const MacroGrams.line(protein: 1, carbs: 2, fat: 3),
        locale: const Locale('en'),
      );

      final l10n = await _l10n(tester);
      final rich = tester.widget<Text>(find.byType(Text));
      expect(
        rich.textSpan!.toPlainText(),
        contains('${l10n.macroGramsCarbsShort}\u00A0'),
      );
    });

    testWidgets('colours only the numbers, the letters stay muted', (
      tester,
    ) async {
      await _pump(
        tester,
        const MacroGrams.line(protein: 14, carbs: 51, fat: 13),
      );

      final rich = tester.widget<Text>(find.byType(Text));
      expect(rich.style?.color, FoodLabelColors.light.muted);
      final protein = _spanColor(tester, '14')!;
      final carbs = _spanColor(tester, '51')!;
      final fat = _spanColor(tester, '13')!;
      expect(protein, isNot(FoodLabelColors.light.muted));
      expect(<Color>{protein, carbs, fat}, hasLength(3));
      expect(_lightness(protein), lessThanOrEqualTo(0.38 + 0.001));
    });

    testWidgets('reads one sentence for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const MacroGrams.line(protein: 14, carbs: 51, fat: 13),
      );

      expect(
        find.bySemanticsLabel(
          'Eiweiß 14 Gramm, Kohlenhydrate 51 Gramm, Fett 13 Gramm',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

Future<AppLocalizations> _l10n(WidgetTester tester) async {
  final context = tester.element(find.byType(MacroGrams));
  return AppLocalizations.of(context)!;
}
