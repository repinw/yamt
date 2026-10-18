import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/plan_shortage_reminders.dart';
import 'package:yamt/features/inventory/presentation/widgets/plan_shortage_reminder_listener.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_plan_needs_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_local_notifications.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/helpers/memory_app_preferences.dart';

final _now = DateTime(2026, 10, 7, 9);
final _tomorrow = DateTime(2026, 10, 8);

/// Oats in stock: 100 g left of a 500 g pack.
class _StockRepository with InventoryItemWholeListWrites {
  final _items = [
    InventoryItem.create(
      id: 'oats',
      name: 'Haferflocken',
      entryDate: DateTime(2026, 10),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 100,
      amountUnit: InventoryAmountUnit.gram,
    ),
  ];

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    // A real stream answers after a gap, like Firestore.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield _items;
  }

  @override
  Future<List<InventoryItem>> readAll() async => _items;
  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;
  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

typedef _Harness = ({
  FakeLocalNotifications notifications,
  FakeShoppingListRepository shopping,
  MemoryAppPreferences preferences,
});

/// The app at home with the reminder listener, and a porridge plan for
/// tomorrow that the oats in stock cannot cover.
Future<_Harness> _pumpApp(WidgetTester tester) async {
  final notifications = FakeLocalNotifications();
  final shopping = FakeShoppingListRepository();
  addTearDown(shopping.dispose);
  final preferences = MemoryAppPreferences();
  final navigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      navigatorKeyProvider.overrideWithValue(navigatorKey),
      appPreferencesProvider.overrideWithValue(preferences),
      localNotificationsProvider.overrideWithValue(notifications),
      clockProvider.overrideWithValue(() => _now),
      inventoryItemRepositoryProvider.overrideWithValue(_StockRepository()),
      shoppingListRepositoryProvider.overrideWithValue(shopping),
      plannedEntryRepositoryProvider.overrideWithValue(
        FakePlannedEntryRepository(
          plans: [
            CalorieEntry.create(
              id: 'porridge',
              userId: 'user-1',
              name: 'Haferflocken',
              mealType: MealType.breakfast,
              consumedAmount: 300,
              consumedUnit: ConsumedUnit.grams,
              per100Kcal: 370,
              per100Protein: 13,
              per100Carbs: 59,
              per100Fat: 7,
              sourceInventoryItemId: 'oats',
              loggedAt: _tomorrow.add(const Duration(hours: 8)),
              createdAt: _now,
              updatedAt: _now,
            ),
          ],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) =>
            PlanShortageReminderListener(child: child ?? const SizedBox()),
      ),
    ),
  );
  final id = planShortageNotificationId(_tomorrow);
  for (var i = 0; i < 50 && !notifications.scheduled.containsKey(id); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return (
    notifications: notifications,
    shopping: shopping,
    preferences: preferences,
  );
}

Future<void> _tapReminder(WidgetTester tester, _Harness app) async {
  app.notifications.tap(planShortageReminderPayload(_tomorrow));
  final dialog = find.byType(ShoppingPlanNeedsDialog);
  for (var i = 0; i < 50 && dialog.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(dialog, findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the reminder the day before puts the missing food on the list', (
    tester,
  ) async {
    final app = await _pumpApp(tester);

    expect(app.notifications.permissionRequests, 1);
    expect(app.notifications.scheduled[planShortageNotificationId(_tomorrow)], (
      at: DateTime(2026, 10, 7, 17),
      title: '1 ingredient missing for tomorrow',
      payload: planShortageReminderPayload(_tomorrow),
    ));

    await _tapReminder(tester, app);
    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.addKey));
    for (var i = 0; i < 50 && app.shopping.savedItems.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(app.shopping.savedItems.single.name, 'Haferflocken');
    expect(
      app.preferences.getStringSync('plan_shortage_reminder_quiet_days_v1'),
      '2026-10-8',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Don\'t ask again" turns the reminder off', (tester) async {
    final app = await _pumpApp(tester);

    await _tapReminder(tester, app);
    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.neverAskKey));
    await tester.pumpAndSettle();

    expect(
      app.preferences.getStringSync('plan_shortage_reminder_off_v1'),
      'set',
    );
    expect(app.notifications.scheduled, isEmpty);
    expect(app.shopping.savedItems, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
