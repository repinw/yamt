import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';

import 'acceptance_harness.dart';

void main() {
  testWidgets('K1: the bar shows the four tabs in normal case, in order', (
    tester,
  ) async {
    await pumpHomeShell(tester);

    final bar = find.byType(HomeBottomNavBar);
    Finder word(String text) =>
        find.descendant(of: bar, matching: find.text(text));
    const words = ['Tagebuch', 'Vorrat', 'Kochbuch', 'Fortschritt'];
    for (final text in words) {
      expect(word(text), findsOneWidget, reason: text);
    }
    final xs = [for (final text in words) tester.getCenter(word(text)).dx];
    expect(xs, orderedEquals([...xs]..sort()), reason: 'order of the tabs');
    for (final text in words) {
      expect(word(text.toUpperCase()), findsNothing, reason: text);
    }
  });
}
