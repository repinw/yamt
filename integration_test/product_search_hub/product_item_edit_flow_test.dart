import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_item_edit_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _openKey = Key('open_item_edit');

/// Oat milk in stock with everything the editor asks for.
final InventoryItem _oatMilk = InventoryItem.create(
  id: 'oat-milk',
  name: 'Haferdrink',
  brand: 'Oatly',
  barcode: '7394376616037',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Rewe',
  quantity: 1,
  weight: '1000 ml',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 46,
    per100Fat: 1.5,
    per100SaturatedFat: 0.2,
    per100Carbs: 6.7,
    per100Sugar: 4,
    per100Protein: 1,
    per100Salt: 0.1,
  ),
).withDerivedAmount();

/// Holds the Vorrat in memory and streams it asynchronously.
class _MemoryItems with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;
  final writes = <List<InventoryItem>>[];

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    yield List.of(items);
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    writes.add(items);
    this.items = List.of(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

/// Records every photo upload; the edit takes no photos.
class _Photos implements ProductPhotoRepository {
  final uploads = <String>[];

  @override
  Future<ProductPhoto?> loadCameraPhoto() async => null;

  @override
  Future<String?> loadBarcode(ProductPhoto photo) async => null;

  @override
  Future<ProductFrontDetails> loadFrontDetails(ProductPhoto photo) =>
      throw UnimplementedError();

  @override
  Future<ProductPhotoUpload> saveProductPhotos({
    required ProductPhoto? front,
    required ProductPhoto? nutritionTable,
    required String barcode,
    required String name,
  }) async {
    uploads.add(barcode);
    return ProductPhotoUpload(frontAddress: null, done: Future<void>.value());
  }
}

typedef _Harness = ({
  _MemoryItems items,
  _Photos photos,
  List<InventoryReceiptManualProductResult?> results,
});

/// Opens the editor of the stock item [_oatMilk] on its route, as the item
/// hub's "Bearbeiten" does, and records what the route returns.
Future<_Harness> _openEditor(WidgetTester tester) async {
  final items = _MemoryItems([_oatMilk]);
  final photos = _Photos();
  final results = <InventoryReceiptManualProductResult?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () async => results.add(
                await context.push<InventoryReceiptManualProductResult>(
                  AppRoutes.homeInventoryItemEditPath(_oatMilk.id),
                ),
              ),
              child: const Text('open'),
            ),
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

  final container = ProviderContainer(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(items),
      productPhotoRepositoryProvider.overrideWithValue(photos),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('de'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  expect(find.byType(InventoryReceiptManualProductEditorPage), findsOneWidget);
  return (items: items, photos: photos, results: results);
}

Finder _buttonLabel(String label) => find.descendant(
  of: find.byKey(ManualProductDetailsForm.saveKey),
  matching: find.text(label),
);

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
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('"Fertig" closes an unchanged stock item without saving', (
    tester,
  ) async {
    final harness = await _openEditor(tester);

    expect(_buttonLabel('Fertig'), findsOneWidget);
    // The same value written another way is no change.
    await _enter(tester, ManualProductFormField.fat, '1,50');
    expect(_buttonLabel('Fertig'), findsOneWidget);

    await _tapButton(tester);

    expect(find.byKey(_openKey), findsOneWidget);
    expect(harness.results, [null]);
    expect(harness.photos.uploads, isEmpty);
    expect(harness.items.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Änderungen speichern" returns the changed stock item', (
    tester,
  ) async {
    final harness = await _openEditor(tester);

    await _enter(tester, ManualProductFormField.kcal, '52');
    expect(_buttonLabel('Änderungen speichern'), findsOneWidget);

    await _tapButton(tester);

    expect(find.byKey(_openKey), findsOneWidget);
    final edited = harness.results.single!.item;
    expect(edited.id, _oatMilk.id);
    expect(edited.nutrition?.per100Kcal, 52);
    expect(edited.name, 'Haferdrink');
    expect(tester.takeException(), isNull);
  });
}
