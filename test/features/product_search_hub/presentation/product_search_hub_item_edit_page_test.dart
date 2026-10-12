import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_item_edit_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';

const _openKey = Key('open_item_edit');

/// Oat milk in stock with everything the editor asks for.
final InventoryItem _oatMilk = _milk(barcode: '7394376616037', salt: 0.1);

InventoryItem _milk({String? barcode, double? salt}) => InventoryItem.create(
  id: 'oat-milk',
  name: 'Oat milk',
  barcode: barcode,
  entryDate: DateTime(2026, 10, 2),
  storeName: 'Rewe',
  quantity: 1,
  weight: '1000 ml',
  nutrition: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 46,
    per100Fat: 1.5,
    per100SaturatedFat: 0.2,
    per100Carbs: 6.7,
    per100Sugar: 4,
    per100Protein: 1,
    per100Salt: salt,
  ),
).withDerivedAmount();

/// Streams the Vorrat asynchronously, like Firestore.
class _Items with InventoryItemWholeListWrites {
  new(this.items);

  final List<InventoryItem> items;

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    await Future<void>.delayed(Duration.zero);
    yield items;
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

/// Opens the editor of [item] from a home page and records how it closed.
Future<List<InventoryReceiptManualProductResult?>> _openEditor(
  WidgetTester tester,
  InventoryItem item,
) async {
  final results = <InventoryReceiptManualProductResult?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: FilledButton(
            key: _openKey,
            onPressed: () async => results.add(
              await context.push<InventoryReceiptManualProductResult>(
                AppRoutes.homeInventoryItemEditPath(item.id),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryItemEdit,
        builder: (context, state) => ProductSearchHubItemEditPage(
          itemId: state.pathParameters['itemId']!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(_Items([item])),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  return results;
}

Finder _buttonLabel(String label) => find.descendant(
  of: find.byKey(ManualProductDetailsForm.saveKey),
  matching: find.text(label),
);

bool _isEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(find.byKey(ManualProductDetailsForm.saveKey))
    .enabled;

Future<void> _enter(
  WidgetTester tester,
  ManualProductFormField field,
  String text,
) async {
  await tester.ensureVisible(find.byKey(field.key));
  await tester.enterText(
    find.descendant(
      of: find.byKey(field.key),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

Future<void> _tapButton(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
  await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unchanged item says "Done", which closes without a result', (
    tester,
  ) async {
    final results = await _openEditor(tester, _oatMilk);

    expect(find.text('Oat milk'), findsWidgets);
    expect(_buttonLabel('Done'), findsOneWidget);
    expect(_isEnabled(tester), isTrue);

    // A value that reads the same is no change.
    await _enter(tester, ManualProductFormField.fat, '1,50');
    expect(_buttonLabel('Done'), findsOneWidget);

    await _tapButton(tester);

    expect(find.byKey(_openKey), findsOneWidget);
    expect(results, [null]);
  });

  testWidgets('a changed item says "Save changes" and returns the edit', (
    tester,
  ) async {
    final results = await _openEditor(tester, _oatMilk);

    await _enter(tester, ManualProductFormField.kcal, '52');
    expect(_buttonLabel('Save changes'), findsOneWidget);

    await _enter(tester, ManualProductFormField.kcal, '46');
    expect(_buttonLabel('Done'), findsOneWidget);

    await _enter(tester, ManualProductFormField.kcal, '52');
    await _tapButton(tester);

    expect(find.byKey(_openKey), findsOneWidget);
    final edited = results.single!.item;
    expect(edited.id, 'oat-milk');
    expect(edited.nutrition?.per100Kcal, 52);
    expect(edited.nutrition?.per100Fat, 1.5);
  });

  testWidgets('a missing value does not block "Done" but a save', (
    tester,
  ) async {
    // An old stock item without salt and without a barcode decision.
    await _openEditor(tester, _milk());

    expect(_buttonLabel('Done'), findsOneWidget);
    expect(_isEnabled(tester), isTrue);
    expect(find.textContaining('Still missing'), findsOneWidget);

    await _enter(tester, ManualProductFormField.name, 'Barista oat milk');

    expect(_buttonLabel('Save changes'), findsOneWidget);
    expect(_isEnabled(tester), isFalse);
  });
}
