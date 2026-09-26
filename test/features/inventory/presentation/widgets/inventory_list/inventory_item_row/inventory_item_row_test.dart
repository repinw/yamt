import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/remaining_progress_bar.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../shoppinglist/support/fake_shopping_list_repository.dart';

const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');
const _usedUpConfirmKey = Key('inventory_item_hub_shopping_list_button');
const _shoppingListActionKey = Key('eat_item_action_shopping_list');
const _editActionKey = Key('eat_item_action_edit');
const _removeActionKey = Key('eat_item_action_remove');

InventoryItem _milk() {
  return InventoryItem.create(
    id: 'milk',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1,
    brand: 'Acme',
  );
}

class _RecordingInventoryItemsController extends InventoryItemsController {
  final boughtAgain = <String>[];
  final stagedAmounts = <int>[];
  final deleted = <String>[];
  final discarded = <(String, int, InventoryDiscardReason)>[];

  @override
  Future<bool> deleteItem(String itemId) async {
    deleted.add(itemId);
    return true;
  }

  @override
  Future<InventoryItemDiscardResult?> throwAwayItemDetailed(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  ) async {
    discarded.add((itemId, amount, reason));
    return (discardEventId: 'discard-$itemId', removedAmount: amount);
  }

  @override
  List<InventoryItem> build() => const <InventoryItem>[];

  @override
  Future<ShoppingListRevert?> buyAgainItem(InventoryItem item) async {
    boughtAgain.add(item.id);
    return const <String, ShoppingListItem?>{};
  }

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    stagedAmounts.add(amount);
    return null;
  }
}

Future<_RecordingInventoryItemsController> _pumpRow(
  WidgetTester tester, {
  InventoryItem? item,
  bool onShoppingList = false,
  bool isSelectionMode = false,
  VoidCallback? onSelectionToggle,
}) async {
  final controller = _RecordingInventoryItemsController();
  final shoppingRepository = FakeShoppingListRepository(
    initialItems: [
      if (onShoppingList)
        const ShoppingListItem(
          id: 'milk-on-list',
          name: 'Milk',
          brand: 'Acme',
          normalizedName: 'milk',
          normalizedBrand: 'acme',
          quantity: 1,
          estimatedUnitPrice: 1,
        ),
    ],
  );
  addTearDown(shoppingRepository.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemsControllerProvider.overrideWith(() => controller),
        shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InventoryItemRow(
            item: item ?? _milk(),
            isSelectionMode: isSelectionMode,
            onSelectionToggle: onSelectionToggle,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openHub(WidgetTester tester) async {
  await tester.tap(find.text('Milk'));
  await tester.pumpAndSettle();
}

Future<void> _tapAction(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the image left of brand, name and stock bar', (
    tester,
  ) async {
    await _pumpRow(tester);

    final imageRect = tester.getRect(find.byType(InventoryItemImageTile));
    final nameRect = tester.getRect(find.text('Milk'));
    final progressRect = tester.getRect(find.byType(RemainingProgressBar));

    expect(imageRect.width, 64);
    expect(nameRect.left, greaterThan(imageRect.right));
    expect(progressRect.left, greaterThan(imageRect.right));
    expect(progressRect.top, greaterThan(nameRect.bottom));
    expect(progressRect.bottom, lessThanOrEqualTo(imageRect.bottom + 1));
    expect(find.byType(InventoryPrimaryActionButton), findsNothing);
  });

  testWidgets('a tap opens the item hub with the eat page and the actions', (
    tester,
  ) async {
    await _pumpRow(tester);

    await _openHub(tester);

    expect(find.byKey(_confirmKey), findsOneWidget);
    expect(find.byType(EatItemActionsCard), findsOneWidget);
    expect(find.text('Item'), findsOneWidget);
    expect(find.text('Replace product'), findsOneWidget);
  });

  testWidgets('logging from the hub stages the stock of the item', (
    tester,
  ) async {
    final controller = await _pumpRow(
      tester,
      item: InventoryItem.create(
        id: 'milk',
        name: 'Milk',
        entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
        storeName: 'Store',
        quantity: 1,
        weight: '500g',
      ).withDerivedAmount(weight: '500g', quantity: 1),
    );
    await _openHub(tester);
    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '100');
    await tester.pump();

    await tester.ensureVisible(find.byKey(_confirmKey));
    await tester.tap(find.byKey(_confirmKey));
    await tester.pumpAndSettle();

    expect(find.byType(EatItemActionsCard), findsNothing);
    expect(controller.stagedAmounts, hasLength(1));
    expect(find.text('Action failed. Please try again.'), findsOneWidget);
  });

  testWidgets('the shopping list action buys again and keeps the hub open', (
    tester,
  ) async {
    final controller = await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _shoppingListActionKey);

    expect(controller.boughtAgain, <String>['milk']);
    expect(find.byType(EatItemActionsCard), findsOneWidget);
    expect(find.text('Item added to shopping list.'), findsOneWidget);
  });

  testWidgets('an item on the shopping list disables the shopping action', (
    tester,
  ) async {
    await _pumpRow(tester, onShoppingList: true);
    await _openHub(tester);

    expect(find.text('On the shopping list'), findsOneWidget);
    await _tapAction(tester, _shoppingListActionKey);
    expect(find.byType(EatItemActionsCard), findsOneWidget);
  });

  testWidgets('the edit action opens the item editor', (tester) async {
    await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _editActionKey);

    expect(find.text('Edit inventory item'), findsOneWidget);
    expect(find.text('Discounts'), findsNothing);
  });

  testWidgets('editing a partly eaten item shows a hint instead', (
    tester,
  ) async {
    final partialItem =
        InventoryItem.create(
              id: 'milk',
              name: 'Milk',
              entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
              storeName: 'Store',
              quantity: 1,
              weight: '500g',
            )
            .withDerivedAmount(weight: '500g', quantity: 1)
            .copyWith(currentAmount: 250);
    await _pumpRow(tester, item: partialItem);
    await _openHub(tester);

    await _tapAction(tester, _editActionKey);

    expect(
      find.text(
        'You can edit the item only while it is still fully available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit inventory item'), findsNothing);
  });

  testWidgets('cancelling the remove dialog returns to the hub', (
    tester,
  ) async {
    final controller = await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _removeActionKey);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(EatItemActionsCard), findsOneWidget);
    expect(controller.deleted, isEmpty);
    expect(controller.discarded, isEmpty);
  });

  testWidgets('closing the editor without changes returns to the hub', (
    tester,
  ) async {
    await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _editActionKey);
    await tester.ensureVisible(find.text('Apply changes'));
    await tester.tap(find.text('Apply changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit inventory item'), findsNothing);
    expect(find.byType(EatItemActionsCard), findsOneWidget);
  });

  testWidgets('the remove action deletes the item completely', (tester) async {
    final controller = await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _removeActionKey);
    await tester.tap(find.text('Delete completely'));
    await tester.pumpAndSettle();

    expect(controller.deleted, <String>['milk']);
    expect(find.byType(EatItemActionsCard), findsNothing);
  });

  testWidgets('the remove action discards an amount with a reason', (
    tester,
  ) async {
    final controller = await _pumpRow(tester);
    await _openHub(tester);

    await _tapAction(tester, _removeActionKey);
    await tester.tap(find.text('Thrown away'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '1',
    );
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')).last,
    );
    await tester.pumpAndSettle();

    expect(controller.discarded, [('milk', 1, InventoryDiscardReason.expired)]);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('a used-up item puts the item on the shopping list', (
    tester,
  ) async {
    final controller = await _pumpRow(
      tester,
      item: _milk().copyWith(quantity: 0),
    );
    await _openHub(tester);

    expect(find.byKey(_confirmKey), findsNothing);
    await tester.tap(find.byKey(_usedUpConfirmKey));
    await tester.pumpAndSettle();

    expect(controller.boughtAgain, <String>['milk']);
  });

  testWidgets('a tap in selection mode toggles the selection', (tester) async {
    var toggles = 0;
    await _pumpRow(
      tester,
      isSelectionMode: true,
      onSelectionToggle: () => toggles++,
    );

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(toggles, 1);
    expect(find.byType(EatItemActionsCard), findsNothing);
  });
}
