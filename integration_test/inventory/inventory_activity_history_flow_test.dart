import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _StreamingInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  _StreamingInventoryActivityEventRepository(
    List<InventoryActivityEvent> events,
  ) : _events = List<InventoryActivityEvent>.from(events);

  final StreamController<List<InventoryActivityEvent>> _controller =
      StreamController<List<InventoryActivityEvent>>.broadcast();
  List<InventoryActivityEvent> _events;

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    emit(<InventoryActivityEvent>[...events, ..._events]);
    return true;
  }

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return Stream<List<InventoryActivityEvent>>.multi((controller) {
      controller.add(_limitedEvents(limit));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  void emit(List<InventoryActivityEvent> events) {
    _events = List<InventoryActivityEvent>.from(events);
    _controller.add(_limitedEvents(100));
  }

  List<InventoryActivityEvent> _limitedEvents(int limit) {
    return List<InventoryActivityEvent>.from(_events.take(limit));
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this.items);

  final List<InventoryItem> items;

  @override
  Future<List<InventoryItem>> build() async {
    return items;
  }
}

class _StaticPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }
}

class _StaticShoppingListController extends ShoppingListController {
  @override
  FutureOr<List<ShoppingListItem>> build() {
    return const <ShoppingListItem>[];
  }
}

class _InventoryActivityHistoryHarness {
  const _InventoryActivityHistoryHarness({
    required this.app,
    required this.activityRepository,
  });

  final Widget app;
  final _StreamingInventoryActivityEventRepository activityRepository;
}

const _alex = InventoryActivityActor(userId: 'alex', displayName: 'Alex');
const _sam = InventoryActivityActor(userId: 'sam', displayName: 'Sam');

@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  PreparedMealsController,
  preparedMealImagePicker,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
  inventoryActivityEvents,
])
_InventoryActivityHistoryHarness _buildHarness() {
  final stockItem = _inventoryItem(id: 'milk', name: 'Milk');
  final events = <InventoryActivityEvent>[
    _activityEvent(
      id: 'event-new',
      type: InventoryActivityEventType.itemAdded,
      actor: _alex,
      item: stockItem,
      amount: 1,
      happenedAt: DateTime(2026, 4, 8, 13, 30),
    ),
    _activityEvent(
      id: 'event-old',
      type: InventoryActivityEventType.itemConsumed,
      actor: _sam,
      item: _inventoryItem(id: 'bread', name: 'Bread'),
      amount: 2,
      happenedAt: DateTime(2026, 4, 7, 9),
    ),
  ];
  final activityRepository = _StreamingInventoryActivityEventRepository(events);
  addTearDown(activityRepository.dispose);

  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(const <InventoryItem>[]),
      ),
      preparedMealsControllerProvider.overrideWith(
        _StaticPreparedMealsController.new,
      ),
      shoppingListControllerProvider.overrideWith(
        _StaticShoppingListController.new,
      ),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        activityRepository,
      ),
    ],
  );
  addTearDown(container.dispose);

  return _InventoryActivityHistoryHarness(
    activityRepository: activityRepository,
    app: UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InventoryPage(includeHomeShellChrome: true),
        ),
      ),
    ),
  );
}

InventoryActivityEvent _activityEvent({
  required String id,
  required InventoryActivityEventType type,
  required InventoryActivityActor actor,
  required InventoryItem item,
  required int amount,
  required DateTime happenedAt,
}) {
  return InventoryActivityEvent.fromStockChange(
    id: id,
    type: type,
    actor: actor,
    item: item,
    amount: amount,
    beforeQuantity: null,
    afterQuantity: null,
    beforeCurrentAmount: null,
    afterCurrentAmount: null,
    happenedAt: happenedAt,
  );
}

InventoryItem _inventoryItem({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 8),
    storeName: 'Store',
    quantity: 1,
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  PreparedMealsController,
  preparedMealImagePicker,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
  inventoryActivityEvents,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('history opens from inventory top bar and streams new events', (
    tester,
  ) async {
    final harness = _buildHarness();

    await tester.pumpWidget(harness.app);
    await _pumpUntilFound(
      tester,
      find.byIcon(Icons.history_rounded),
      description: 'history app bar action',
    );
    final emptyStockMessage = find.text(
      'No items in your fridge yet. Scan a receipt or add foods manually.',
    );
    await _pumpUntilFound(
      tester,
      emptyStockMessage,
      description: 'empty inventory stock view',
    );

    await tester.tap(find.byIcon(Icons.history_rounded));
    await _pumpUntilFound(
      tester,
      find.text('Alex added 1 item of Milk.'),
      description: 'newest history entry',
    );

    final dayFormat = DateFormat.yMMMd('en');
    expect(find.text(dayFormat.format(DateTime(2026, 4, 8))), findsOneWidget);
    expect(find.text(dayFormat.format(DateTime(2026, 4, 7))), findsOneWidget);
    expect(find.text('Sam ate 2 items of Bread.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alex added 1 item of Milk.')).dy,
      lessThan(tester.getTopLeft(find.text('Sam ate 2 items of Bread.')).dy),
    );

    harness.activityRepository.emit(<InventoryActivityEvent>[
      _activityEvent(
        id: 'event-live',
        type: InventoryActivityEventType.itemDiscarded,
        actor: _alex,
        item: _inventoryItem(id: 'flour', name: 'Flour'),
        amount: 1,
        happenedAt: DateTime(2026, 4, 9, 8),
      ),
      ...harness.activityRepository._events,
    ]);
    await _pumpUntilFound(
      tester,
      find.text('Alex discarded 1 item of Flour.'),
      description: 'streamed history entry',
    );
    expect(
      tester.getTopLeft(find.text('Alex discarded 1 item of Flour.')).dy,
      lessThan(tester.getTopLeft(find.text('Alex added 1 item of Milk.')).dy),
    );

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await _pumpUntilFound(
      tester,
      find.byIcon(Icons.history_rounded),
      description: 'history action after returning to stock',
    );
    await _pumpUntilFound(
      tester,
      emptyStockMessage,
      description: 'empty inventory stock view after returning',
    );
    expect(find.text('Alex added 1 item of Milk.'), findsNothing);
  });
}
