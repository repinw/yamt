import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_panel.dart';

import 'acceptance_harness.dart';

void main() {
  final menu = find.byKey(HomeShellMenuButton.buttonKey);

  for (final tab in AcceptanceTab.values) {
    testWidgets('K6: ${tab.name} shows the Menü button top left', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab);

      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: menu, matching: find.text('Menü')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: menu, matching: find.text('MENÜ')),
        findsNothing,
      );
      expect(tester.getTopLeft(menu).dx, lessThan(100));
      expect(tester.getTopLeft(menu).dy, lessThan(150));
      expect(toolTexts(tester, menu), [
        'Menü',
      ], reason: 'the word under the icon');
    });

    testWidgets('K6: ${tab.name} shows the Menü button with no food at all', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab, emptyVorrat: true);

      expect(menu, findsOneWidget);
      expect(toolTexts(tester, menu), ['Menü']);
    });

    testWidgets('K7: Menü opens the side menu from ${tab.name}', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab);
      expect(find.byType(HomeMenuPanel), findsNothing);

      await tapAndSettle(tester, menu);

      expect(find.byType(HomeMenuPanel), findsOneWidget);
    });
  }
}
