import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  test('eat request can be built from generic selection', () {
    final loggedAt = DateTime.parse('2026-04-13T20:00:00Z');

    final request = inventoryManualAddEatRequestFromSelection(
      EatSelection(
        inventoryAmount: 380,
        loggedAt: loggedAt,
        mealType: MealType.dinner,
      ),
    );

    expect(request?.inventoryAmount, 380);
    expect(request?.loggedAt, loggedAt);
    expect(request?.mealType, MealType.dinner);
  });

  testWidgets('manual-add eat flow returns false for invalid amount', (
    tester,
  ) async {
    bool? completed;
    final item = InventoryItem.create(
      id: 'milk',
      name: 'Milk',
      entryDate: DateTime.utc(2026),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 100,
      currentAmount: 100,
      amountUnit: InventoryAmountUnit.gram,
    );
    final request = InventoryItemEatRequest(
      inventoryAmount: 0,
      loggedAt: DateTime.utc(2026),
      mealType: MealType.breakfast,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  unawaited(
                    completeInventoryManualAddEatFlow(
                      context: context,
                      item: item,
                      request: request,
                    ).then((value) {
                      completed = value;
                    }),
                  );
                },
                child: const Text('complete'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('complete'));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(find.text('Action failed. Please try again.'), findsOneWidget);
  });
}
