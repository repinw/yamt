import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    show InventoryReceiptManualProductResult;
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_editor_header.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_photo_section.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/auth_user_data_key_session.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';

// A 1x1 PNG, so the photo tiles can decode the "photos".
final Uint8List _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x04, 0x00, 0x00, 0x00, 0xB5, 0x1C, 0x0C, 0x02, 0x00, 0x00, 0x00, //
  0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x64, 0x60, 0x00, 0x00, //
  0x00, 0x06, 0x00, 0x02, 0x30, 0x81, 0xD0, 0x2F, 0x00, 0x00, 0x00, 0x00, //
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _frontUrl = 'gs://bucket/product_images/user-1/photo-1/front.jpg';
const _privateFrontUrl = 'gs://bucket/users/user-1/food_photos/photo-1.jpg';

class _FakePhotoRepository implements ProductPhotoRepository {
  var _photoCount = 0;
  final saved = <String>[];
  final savedPrivate = <String>[];

  /// How many of the next front photos show no package.
  int notPackagePhotos = 0;

  @override
  Future<ProductPhoto?> loadCameraPhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _photoCount++;
    return ProductPhoto(
      path: 'photo-$_photoCount',
      bytes: _pixel,
      mimeType: 'image/png',
    );
  }

  @override
  Future<String?> loadBarcode(ProductPhoto photo) async => null;

  @override
  Future<ProductFrontDetails> loadFrontDetails(ProductPhoto photo) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (notPackagePhotos > 0) {
      notPackagePhotos--;
      throw const ProductFrontNotProductException();
    }
    return const ProductFrontDetails(
      name: 'Haferflocken zart',
      brand: 'REWE Bio',
      quantityLabel: '500 g',
      barcode: '4006381333931',
    );
  }

  @override
  Future<ProductPhotoUpload> saveProductPhotos({
    required ProductPhoto? front,
    required ProductPhoto? nutritionTable,
    required String barcode,
    required String name,
  }) async {
    saved.add(barcode);
    return ProductPhotoUpload(
      frontAddress: front == null ? null : _frontUrl,
      // The upload never ends; the editor saves without waiting for it.
      done: Completer<void>().future,
    );
  }

  @override
  Future<ProductPhotoUpload> savePrivateFrontPhoto(ProductPhoto front) async {
    savedPrivate.add(front.path);
    return ProductPhotoUpload(
      frontAddress: _privateFrontUrl,
      done: Completer<void>().future,
    );
  }
}

/// The Vorrat, which reports each write through its stream like Firestore.
class _FakeStock with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;
  final _writes = StreamController<List<InventoryItem>>.broadcast();

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    this.items = List.of(items);
    _writes.add(List.of(items));
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) =>
      replaceItems([...this.items, ...items]);

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.multi((controller) {
    controller.add(List.of(items));
    final subscription = _writes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
}

/// The shared catalog, which other users read.
class _FakeCatalog implements GlobalFoodItemRepository {
  final appended = <GlobalFoodItem>[];

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    appended.addAll(items);
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async => const [];

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const [];
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() => Stream.value(const []);
}

/// The barcode candidates that other users' scans read.
class _FakeBarcodeCandidates implements GlobalBarcodeCandidateRepository {
  final recorded = <String>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async => const [];

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    recorded.add(barcode);
  }
}

class _FakeNutritionOcrRepository implements NutritionLabelOcrRepository {
  @override
  Future<NutritionLabelOcrResult> readNutritionLabel({
    required Uint8List imageBytes,
    required String mimeType,
    required String barcode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return NutritionLabelOcrResult.succeeded(
      draft: NutritionLabelOcrDraft(
        barcode: barcode,
        per100Kj: 1556,
        per100Kcal: 372,
        per100Fat: 7,
        per100SaturatedFat: 1.3,
        per100Carbs: 58.7,
        per100Sugar: 0.7,
        per100Protein: 13.5,
        per100Salt: 0.01,
      ),
    );
  }
}

Widget _buildHarness({
  required _FakePhotoRepository photos,
  required ValueChanged<Object?> onResult,
}) {
  final config = InventoryReceiptManualProductConfig(
    item: InventoryItem.create(
      id: 'item-1',
      name: '',
      entryDate: DateTime.parse('2026-09-28T10:00:00Z'),
      storeName: 'Rewe',
      quantity: 1,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open_editor'),
              onPressed: () async => onResult(
                await pushManualProductSearchPage<Object?>(
                  context: context,
                  args: ManualProductSearchRouteArgs.editor(
                    config: config,
                    showEatImmediatelyOption: false,
                    initialAction:
                        InventoryReceiptManualProductAction.addToInventory,
                    showActionSelector: false,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        redirect: redirectInvalidManualProductSearchRoute,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      productPhotoRepositoryProvider.overrideWithValue(photos),
      nutritionLabelOcrRepositoryProvider.overrideWithValue(
        _FakeNutritionOcrRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// A Vorrat item without a photo, whose product the user replaces.
final InventoryItem _bread = InventoryItem.create(
  id: 'item-bread',
  name: 'Brot',
  entryDate: DateTime.parse('2026-09-28T10:00:00Z'),
  storeName: 'Rewe',
  quantity: 1,
  weight: '500 g',
).withDerivedAmount();

/// The Vorrat item hub of [_bread] with the real "Replace product" flow:
/// the product search hub picks the product, and the editor makes it.
Widget _buildReplaceHarness({
  required _FakePhotoRepository photos,
  required _FakeStock stock,
  required _FakeCatalog catalog,
  required _FakeBarcodeCandidates barcodeCandidates,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) {
                // The Vorrat page keeps the Vorrat loaded.
                ref.watch(inventoryItemsControllerProvider);
                return FilledButton(
                  key: const Key('open_item_hub'),
                  onPressed: () => InventoryItemHubFlow.open(
                    context: context,
                    ref: ref,
                    item: _bread,
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => ProductSearchHubPage(
          args: resolveProductSearchHubRouteArgs(state.extra),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        redirect: redirectInvalidManualProductSearchRoute,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);

  // Signed out: the hub's shopping list and serving reads stay empty.
  final container = ProviderContainer(
    overrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
      inventoryItemRepositoryProvider.overrideWithValue(stock),
      globalFoodItemRepositoryProvider.overrideWithValue(catalog),
      globalBarcodeCandidateRepositoryProvider.overrideWithValue(
        barcodeCandidates,
      ),
      productPhotoRepositoryProvider.overrideWithValue(photos),
      nutritionLabelOcrRepositoryProvider.overrideWithValue(
        _FakeNutritionOcrRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Types [text] into [field], as the user does when no photo filled it.
Future<void> _enter(
  WidgetTester tester,
  ManualProductFormField field,
  String text,
) async {
  await tester.ensureVisible(find.byKey(field.key));
  await tester.enterText(find.byKey(field.key), text);
  await tester.pumpAndSettle();
}

/// Waits until the snack bar of a photo is gone, so it covers nothing.
Future<void> _waitForSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, ManualProductFormField field) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(field.key),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('two photos fill the product and the front photo is stored', (
    tester,
  ) async {
    final photos = _FakePhotoRepository();
    Object? result;
    await tester.pumpWidget(
      _buildHarness(photos: photos, onResult: (value) => result = value),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_editor')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.pumpAndSettle();
    expect(_text(tester, ManualProductFormField.name), 'Haferflocken zart');
    expect(_text(tester, ManualProductFormField.brand), 'REWE Bio');
    expect(_text(tester, ManualProductFormField.weightAmount), '500');
    expect(_text(tester, ManualProductFormField.barcode), '4006381333931');

    await tester.tap(find.byKey(ManualProductPhotoSection.nutritionTableKey));
    await tester.pumpAndSettle();
    expect(_text(tester, ManualProductFormField.kcal), '372');
    expect(_text(tester, ManualProductFormField.salt), '0.01');

    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.pumpAndSettle();

    expect(photos.saved, ['4006381333931']);
    expect(result, isA<InventoryReceiptManualProductResult>());
    final saved = result! as InventoryReceiptManualProductResult;
    expect(saved.requiresGlobalPersistence, isTrue);
    final item = saved.item;
    expect(item.name, 'Haferflocken zart');
    expect(item.imageUrl, _frontUrl);
  });

  testWidgets('a front photo without a package keeps the product and its '
      'photo private (#658)', (tester) async {
    final photos = _FakePhotoRepository()..notPackagePhotos = 1;
    Object? result;
    await tester.pumpWidget(
      _buildHarness(photos: photos, onResult: (value) => result = value),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_editor')));
    await tester.pumpAndSettle();
    // The photo step says what happens with the photos.
    expect(
      find.byKey(ManualProductPhotoSection.sharingNoticeKey),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.pumpAndSettle();
    expect(_text(tester, ManualProductFormField.name), isEmpty);
    await _waitForSnackBar(tester);

    await tester.tap(find.byKey(ManualProductPhotoSection.nutritionTableKey));
    await tester.pumpAndSettle();
    await _enter(tester, ManualProductFormField.name, 'Brot vom Bäcker');
    await _enter(tester, ManualProductFormField.weightAmount, '500');
    await tester.ensureVisible(
      find.byKey(ManualProductEditorHeader.weightUnitKey),
    );
    await tester.tap(find.byKey(ManualProductEditorHeader.weightUnitKey));
    await tester.pumpAndSettle();
    await _enter(tester, ManualProductFormField.barcode, '4006381333931');

    await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.pumpAndSettle();

    expect(photos.saved, isEmpty);
    expect(photos.savedPrivate, hasLength(1));
    expect(result, isA<InventoryReceiptManualProductResult>());
    final saved = result! as InventoryReceiptManualProductResult;
    expect(saved.requiresGlobalPersistence, isFalse);
    expect(saved.item.name, 'Brot vom Bäcker');
    expect(saved.item.imageUrl, _privateFrontUrl);
  });

  testWidgets('a new front photo with a package shares the product again '
      '(#658)', (tester) async {
    final photos = _FakePhotoRepository()..notPackagePhotos = 1;
    Object? result;
    await tester.pumpWidget(
      _buildHarness(photos: photos, onResult: (value) => result = value),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_editor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.pumpAndSettle();
    await _waitForSnackBar(tester);

    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.pumpAndSettle();
    expect(_text(tester, ManualProductFormField.name), 'Haferflocken zart');
    await tester.tap(find.byKey(ManualProductPhotoSection.nutritionTableKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.pumpAndSettle();

    expect(photos.saved, ['4006381333931']);
    expect(photos.savedPrivate, isEmpty);
    final saved = result! as InventoryReceiptManualProductResult;
    expect(saved.requiresGlobalPersistence, isTrue);
    expect(saved.item.imageUrl, _frontUrl);
  });

  testWidgets('a product whose front photo shows no package replaces the '
      'product of a Vorrat item and stays private (#658)', (tester) async {
    final photos = _FakePhotoRepository()..notPackagePhotos = 1;
    final stock = _FakeStock([_bread]);
    final catalog = _FakeCatalog();
    final barcodeCandidates = _FakeBarcodeCandidates();
    await tester.pumpWidget(
      _buildReplaceHarness(
        photos: photos,
        stock: stock,
        catalog: catalog,
        barcodeCandidates: barcodeCandidates,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_item_hub')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('eat_item_action_replace')),
    );
    await tester.tap(find.byKey(const Key('eat_item_action_replace')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(InventoryReceiptCandidatePickerSheet.manualEntryKey),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductSearchHubPage), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
    await tester.pumpAndSettle();
    await _waitForSnackBar(tester);
    await tester.tap(find.byKey(ManualProductPhotoSection.nutritionTableKey));
    await tester.pumpAndSettle();
    await _enter(tester, ManualProductFormField.name, 'Brot vom Bäcker');
    await _enter(tester, ManualProductFormField.barcode, '4006381333931');
    await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProductSearchHubPage), findsNothing);
    expect(find.byType(InventoryItemHubPage), findsNothing);
    expect(photos.saved, isEmpty);
    expect(photos.savedPrivate, hasLength(1));
    // Neither the catalog nor other users' barcode scans get the product.
    expect(catalog.appended, isEmpty);
    expect(barcodeCandidates.recorded, isEmpty);
    final item = stock.items.single;
    expect(item.id, _bread.id);
    expect(item.name, 'Brot vom Bäcker');
    expect(item.barcode, '4006381333931');
    expect(isPendingGlobalFoodItemId(item.globalFoodItemId), isTrue);
    expect(item.imageUrl, _privateFrontUrl);
    expect(tester.takeException(), isNull);
  });
}
