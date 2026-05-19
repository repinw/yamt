import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_detail/meal_template_detail_actions.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_detail/meal_template_detail_helpers.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/root_navigator_test_utils.dart';

void main() {
  testWidgets(
    'assignment and conversion sheets use root navigator by default',
    (
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
                      selectInventoryAssignments(
                        context: context,
                        row: const IngredientRowData(
                          name: 'Tomato',
                          amountLabel: '2 pieces',
                          requirement: TemplateIngredientRequirement(
                            amount: 2,
                            unit: TemplateIngredientUnit.piece,
                            name: 'Tomato',
                          ),
                        ),
                        inventoryItems: <InventoryItem>[
                          _item(id: 'tomato', name: 'Tomato sauce'),
                        ],
                        onAssignmentChanged: (_) {},
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
        find.text(l10n.preparedMealTemplateDetailSelectionTitle),
        findsOneWidget,
      );

      rootObserver.clear();
      nestedObserver.clear();
      await tester.tap(find.text('Tomato sauce'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.inventoryReceiptReviewManualDataSaveAction),
      );
      await tester.pumpAndSettle();

      expectRootPopupRoutePushed(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
      );
      expect(find.text('Amount per pc (g)'), findsOneWidget);
    },
  );
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
