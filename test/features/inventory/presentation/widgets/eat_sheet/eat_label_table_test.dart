import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _eatenHeader = '1 Portion · geschätzt';
const _rows = [
  NutritionFactsRow(label: 'Energie', per100: '100 kcal', eaten: '250 kcal'),
  NutritionFactsRow(label: 'Fett', per100: '1 g', eaten: '3 g'),
];

Future<void> _pump(
  WidgetTester tester, {
  String? per100Header,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: EatLabelTable(
          rows: _rows,
          eatenHeader: _eatenHeader,
          per100Header: per100Header,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('with a per-100 header the eaten header has its own width', (
    tester,
  ) async {
    await _pump(tester, per100Header: 'pro 100 g');

    expect(
      tester.getSize(find.text(_eatenHeader)).width,
      AppFoodLabel.eatenColumn,
    );
    expect(
      tester.getSize(find.text('pro 100 g')).width,
      AppFoodLabel.per100Column,
    );
  });

  testWidgets('without one the eaten column takes the per-100 width too', (
    tester,
  ) async {
    await _pump(tester);
    const whole =
        AppFoodLabel.per100Column +
        AppFoodLabel.labelColumnGap +
        AppFoodLabel.eatenColumn;

    expect(tester.getSize(find.text(_eatenHeader)).width, whole);
    for (final value in ['250 kcal', '3 g']) {
      expect(tester.getSize(find.text(value)).width, whole);
    }
    expect(find.text('100 kcal'), findsNothing);
  });

  testWidgets('at text scale 1.3 the one-column header breaks only between '
      'words', (tester) async {
    await _pump(tester, textScale: 1.3);

    final header = find.text(_eatenHeader);
    final box = tester.getSize(header);
    final text = tester.widget<Text>(header);
    final style = DefaultTextStyle.of(tester.element(header)).style
        .merge(text.style);
    TextPainter painter(String value, {double maxWidth = double.infinity}) =>
        TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: TextDirection.ltr,
          textScaler: const TextScaler.linear(1.3),
        )..layout(maxWidth: maxWidth);

    // Every word fits the column whole, so a line can only end between words.
    for (final word in _eatenHeader.split(' ')) {
      expect(painter(word).width, lessThanOrEqualTo(box.width), reason: word);
    }
    // Laid out at the column's width, each line ends at a space or the end.
    final wrapped = painter(_eatenHeader, maxWidth: box.width);
    final lines = wrapped.computeLineMetrics();
    expect(box.height, closeTo(wrapped.height, 0.5));
    var offset = 0;
    for (var line = 0; line < lines.length - 1; line++) {
      offset = wrapped.getLineBoundary(TextPosition(offset: offset)).end;
      expect(_eatenHeader[offset - 1], ' ', reason: 'line ${line + 1}');
    }
  });
}
