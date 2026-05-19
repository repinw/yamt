import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_pending_ingredient.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/root_navigator_test_utils.dart';

void main() {
  testWidgets('pending ingredient picker opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();
    late AppLocalizations l10n;

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return TextButton(
                onPressed: () {
                  unawaited(
                    showPendingIngredientSelectionSheet(
                      context: context,
                      ingredient: 'Tomato',
                      inventoryItems: <InventoryItem>[
                        _item(id: 'tomato', name: 'Tomato sauce'),
                      ],
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(
      find.text(l10n.preparedMealPendingIngredientSelectionTitle),
      findsOneWidget,
    );
  });
}

InventoryItem _item({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 300,
    currentAmount: 300,
    amountUnit: InventoryAmountUnit.gram,
  );
}
