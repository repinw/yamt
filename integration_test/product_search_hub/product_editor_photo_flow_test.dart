import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    show InventoryReceiptManualProductResult;
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_photo_section.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

class _FakePhotoRepository implements ProductPhotoRepository {
  var _photoCount = 0;
  final saved = <String>[];

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
    final item = (result! as InventoryReceiptManualProductResult).item;
    expect(item.name, 'Haferflocken zart');
    expect(item.imageUrl, _frontUrl);
  });
}
