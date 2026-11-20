import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';

import 'acceptance_harness.dart';

const Map<AcceptanceTab, String> _words = {
  AcceptanceTab.tagebuch: 'Essen',
  AcceptanceTab.vorrat: 'Hinzufügen',
  AcceptanceTab.kochbuch: 'Kochen',
  AcceptanceTab.fortschritt: 'Erfassen',
};

void main() {
  final button = find.byKey(HomeBottomNavBar.actionKey);

  for (final entry in _words.entries) {
    testWidgets('K3: on ${entry.key.name} the lime button says '
        '"${entry.value}"', (tester) async {
      await pumpHomeShell(tester, tab: entry.key);

      expect(button, findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.text(entry.value)),
        findsOneWidget,
      );
    });
  }

  testWidgets('K4: the lime button keeps its size for every word', (
    tester,
  ) async {
    await pumpHomeShell(tester);
    final sizes = <AcceptanceTab, Size>{};
    for (final tab in AcceptanceTab.values) {
      await switchToTab(tester, tab);
      sizes[tab] = tester.getSize(button);
    }

    expect(sizes.values.toSet(), hasLength(1), reason: '$sizes');
  });

  for (final tab in AcceptanceTab.values) {
    testWidgets('K5: the lime button opens the actions on ${tab.name}', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab);
      expect(find.byType(HomeActionPanel), findsNothing);

      await tapAndSettle(tester, button);

      expect(find.byType(HomeActionPanel), findsOneWidget);
    });
  }
}
