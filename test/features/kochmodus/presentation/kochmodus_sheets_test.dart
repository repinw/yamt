import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';

import 'kochmodus_sheet_pump.dart';

Future<void> _digits(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tapKey(tester, KochmodusWeighSheet.digitKey(int.parse(digit)));
  }
}

FilledButton _confirm(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(KochmodusWeighSheet.confirmKey));

void main() {
  group('weigh sheet', () {
    Future<void> openWeigh(
      WidgetTester tester,
      List<int?> results, {
      int? hint,
      String? sub,
      bool estimate = false,
    }) => pumpSheet<int>(
      tester,
      (context) => KochmodusWeighSheet.show(
        context,
        title: '2 Zwiebeln',
        sub: sub,
        hint: hint,
        estimate: estimate,
      ),
      results,
    );

    testWidgets('the keypad builds the grams and confirms them', (
      tester,
    ) async {
      final results = <int?>[];
      await openWeigh(tester, results, sub: 'Zwiebeln rot · Rezept etwa 160 g');
      final l10n = sheetL10n(tester);
      expect(find.text('2 Zwiebeln'), findsOneWidget);
      expect(find.text('Zwiebeln rot · Rezept etwa 160 g'), findsOneWidget);
      expect(find.text(l10n.kochmodusWeigh.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.cookAmountGrams('0')), findsOneWidget);
      expect(_confirm(tester).onPressed, isNull);

      await _digits(tester, '305');

      expect(find.text(l10n.cookAmountGrams('305')), findsOneWidget);
      expect(find.text(l10n.kochmodusWeighConfirm(305)), findsOneWidget);
      await tapKey(tester, KochmodusWeighSheet.confirmKey);
      expect(results, [305]);
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
    });

    testWidgets('leading zeros do not count', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results);

      await _digits(tester, '007');

      expect(find.text(sheetL10n(tester).cookAmountGrams('7')), findsOneWidget);
      await tapKey(tester, KochmodusWeighSheet.confirmKey);
      expect(results, [7]);
    });

    testWidgets('a scale shows at most five digits', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results);

      await _digits(tester, '123456');

      expect(find.text(sheetL10n(tester).cookAmountGrams('12345')), findsOne);
    });

    testWidgets('the delete key takes the last digit and ends at empty', (
      tester,
    ) async {
      final results = <int?>[];
      await openWeigh(tester, results);
      final l10n = sheetL10n(tester);
      final delete = find.byIcon(Icons.backspace_outlined);

      await _digits(tester, '42');
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text(l10n.cookAmountGrams('4')), findsOneWidget);

      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text(l10n.cookAmountGrams('0')), findsOneWidget);
      expect(_confirm(tester).onPressed, isNull);
    });

    testWidgets('the hint key takes the hint', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results, hint: 160);
      final l10n = sheetL10n(tester);
      expect(find.text(l10n.cookAmountGrams('160')), findsOneWidget);

      await tapKey(tester, KochmodusWeighSheet.hintKey);

      expect(find.text(l10n.kochmodusWeighConfirm(160)), findsOneWidget);
      await tapKey(tester, KochmodusWeighSheet.confirmKey);
      expect(results, [160]);
    });

    testWidgets('without a hint that key stays empty', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results);

      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(KochmodusWeighSheet.hintKey),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an estimate has its own kicker and button', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results, estimate: true);
      final l10n = sheetL10n(tester);

      expect(
        find.text(l10n.kochmodusEstimateKicker.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusWeigh.toUpperCase()), findsNothing);
      await _digits(tester, '90');
      expect(find.text(l10n.kochmodusEstimateConfirm(90)), findsOneWidget);
      await tapKey(tester, KochmodusWeighSheet.confirmKey);
      expect(results, [90]);
    });

    testWidgets('closing the sheet returns nothing', (tester) async {
      final results = <int?>[];
      await openWeigh(tester, results);

      await _digits(tester, '5');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });
}
