import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_scaled_value_text.dart';

void main() {
  Future<double> heightFor(WidgetTester tester, String value) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 40,
              child: DiaryScaledValueText(
                value,
                style: const TextTheme().headlineLarge,
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(DiaryScaledValueText)).height;
  }

  testWidgets('long values shrink without lowering the row height', (
    tester,
  ) async {
    final shortHeight = await heightFor(tester, '5');
    final longHeight = await heightFor(tester, '12.345');

    expect(longHeight, shortHeight);
  });
}
