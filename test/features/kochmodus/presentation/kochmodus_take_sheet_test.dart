import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';

import 'kochmodus_sheet_pump.dart';

void main() {
  Future<List<KochmodusTakeAnswer?>> open(
    WidgetTester tester, {
    required double textScale,
    bool fromRecipe = true,
  }) async {
    final results = <KochmodusTakeAnswer?>[];
    await pumpSheet<KochmodusTakeAnswer>(
      tester,
      (context) => KochmodusTakeSheet.show(
        context,
        line: '400 g Hähnchenbrust',
        food: 'Hähnchenbrustfilet · 500 g da',
        keep: '400 g',
        fromRecipe: fromRecipe,
        all: '500 g',
      ),
      results,
      width: 360,
      height: 640,
      textScale: textScale,
    );
    return results;
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    group('at 360x640 and text scale $scale', () {
      testWidgets('does not overflow', (tester) async {
        await open(tester, textScale: scale);

        expect(tester.takeException(), isNull);
      });

      for (final answer in KochmodusTakeAnswer.values) {
        testWidgets('reaches the answer ${answer.name}', (tester) async {
          final results = await open(tester, textScale: scale);
          final key = find.byKey(KochmodusTakeSheet.answerKey(answer));

          await tester.ensureVisible(key);
          await tester.pumpAndSettle();
          await tester.tap(key);
          await tester.pumpAndSettle();

          expect(results, [answer]);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
