import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_list_view_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_sort_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpSheet(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InventorySortSheet()),
        ),
      ),
    );
  }

  InventoryItemSortMode sortMode() =>
      container.read(inventoryListViewControllerProvider).preferences.sortMode;

  testWidgets('picking a field starts with its default direction and '
      'tapping it again flips it', (tester) async {
    await pumpSheet(tester);
    expect(find.text('Neueste zuerst'), findsOneWidget);

    await tester.tap(
      find.byKey(
        InventorySortSheet.criterionKey(InventorySortCriterion.alphabetical),
      ),
    );
    await tester.pump();
    expect(sortMode(), InventoryItemSortMode.alphabeticalAscending);
    expect(find.text('A bis Z'), findsOneWidget);

    await tester.tap(
      find.byKey(
        InventorySortSheet.criterionKey(InventorySortCriterion.alphabetical),
      ),
    );
    await tester.pump();
    expect(sortMode(), InventoryItemSortMode.alphabeticalDescending);
  });

  testWidgets('the switches change the list settings at once', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(InventorySortSheet.hideConsumedKey));
    await tester.tap(find.byKey(InventorySortSheet.groupByReceiptKey));
    await tester.pump();

    final preferences = container
        .read(inventoryListViewControllerProvider)
        .preferences;
    expect(preferences.hideConsumed, isFalse);
    expect(preferences.groupByReceipt, isTrue);
  });
}
