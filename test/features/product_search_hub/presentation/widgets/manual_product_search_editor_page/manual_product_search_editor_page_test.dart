import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    show InventoryReceiptManualProductResult;
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
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

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8'
  'AAAAASUVORK5CYII=',
);

const _frontUrl = 'gs://bucket/product_images/user-1/photo-1/front.jpg';

const _privateUrl = 'gs://bucket/users/user-1/food_photos/photo-1.jpg';

/// Takes a front photo, but the AI fails on it with [frontError].
class _FakePhotoRepository implements ProductPhotoRepository {
  new({required this.frontError, this.cameraError});

  final Exception frontError;

  /// Thrown by the camera instead of taking a photo.
  final Exception? cameraError;
  final savedNames = <String>[];
  final savedPrivate = <String>[];

  @override
  Future<ProductPhoto?> loadCameraPhoto() async {
    final error = cameraError;
    if (error != null) throw error;
    return ProductPhoto(path: 'front', bytes: _pixel, mimeType: 'image/png');
  }

  @override
  Future<String?> loadBarcode(ProductPhoto photo) async => null;

  @override
  Future<ProductFrontDetails> loadFrontDetails(ProductPhoto photo) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    throw frontError;
  }

  @override
  Future<ProductPhotoUpload> saveProductPhotos({
    required ProductPhoto? front,
    required ProductPhoto? nutritionTable,
    required String barcode,
    required String name,
  }) async {
    savedNames.add(name);
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
      frontAddress: _privateUrl,
      done: Completer<void>().future,
    );
  }
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required Locale locale,
  required _FakePhotoRepository photos,
  required ValueChanged<Object?> onResult,
}) async {
  final config = InventoryReceiptManualProductConfig(
    item: InventoryItem.create(
      id: 'item-1',
      name: '',
      entryDate: DateTime.parse('2026-10-10T10:00:00Z'),
      storeName: 'Rewe',
      quantity: 1,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: FilledButton(
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
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        redirect: redirectInvalidManualProductSearchRoute,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [productPhotoRepositoryProvider.overrideWithValue(photos)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open_editor')));
  await tester.pumpAndSettle();
}

/// Takes the front photo and waits until the AI gave up on it.
Future<void> _takeFrontPhoto(WidgetTester tester) async {
  await tester.tap(find.byKey(ManualProductPhotoSection.frontKey));
  await tester.pumpAndSettle();
}

/// Types what the AI would have read, as the user does after the error.
Future<void> _typeProduct(WidgetTester tester) async {
  for (final (field, text) in [
    (ManualProductFormField.name, 'Haferflocken zart'),
    (ManualProductFormField.weightAmount, '500'),
    (ManualProductFormField.barcode, '4006381333931'),
    (ManualProductFormField.kcal, '372'),
    (ManualProductFormField.fat, '7'),
    (ManualProductFormField.saturatedFat, '1.3'),
    (ManualProductFormField.carbs, '58.7'),
    (ManualProductFormField.sugar, '0.7'),
    (ManualProductFormField.protein, '13.5'),
    (ManualProductFormField.salt, '0.01'),
  ]) {
    await tester.ensureVisible(find.byKey(field.key));
    await tester.enterText(find.byKey(field.key), text);
  }
  await tester.ensureVisible(
    find.byKey(ManualProductEditorHeader.weightUnitKey),
  );
  await tester.tap(find.byKey(ManualProductEditorHeader.weightUnitKey));
  await tester.pumpAndSettle();
}

void main() {
  for (final (reason, error, photoUrl) in <(String, Exception, String)>[
    ('offline', const SocketException('Failed host lookup'), _frontUrl),
    (
      'without a readable name',
      const ProductFrontUnreadableException(),
      _frontUrl,
    ),
    // A front without a package stays the user's private photo (#658).
    ('without a package', const ProductFrontNotProductException(), _privateUrl),
  ]) {
    testWidgets('a front the AI reads $reason says nothing, and the typed '
        'product saves with the photo', (tester) async {
      final photos = _FakePhotoRepository(frontError: error);
      Object? result;
      await _pumpEditor(
        tester,
        locale: const Locale('de'),
        photos: photos,
        onResult: (value) => result = value,
      );

      await _takeFrontPhoto(tester);

      expect(find.byType(AppSnackBarView), findsNothing);
      final name = tester.widget<TextField>(
        find.byKey(ManualProductFormField.name.key),
      );
      expect(name.controller?.text, isEmpty);

      await _typeProduct(tester);
      await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
      await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
      await tester.pumpAndSettle();

      final item = (result! as InventoryReceiptManualProductResult).item;
      expect(item.name, 'Haferflocken zart');
      expect(item.imageUrl, photoUrl);
      expect(photos.savedNames.length + photos.savedPrivate.length, 1);
    });
  }

  for (final (camera, message) in <(Exception, String)>[
    (
      const ProductPhotoCameraUnsupportedException(),
      'Auf diesem Gerät gehen keine Fotos.',
    ),
    (
      Exception('permission denied'),
      'Das Foto konnte nicht aufgenommen werden.',
    ),
  ]) {
    testWidgets('the camera still reports its own problem: $message', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        locale: const Locale('de'),
        photos: _FakePhotoRepository(
          frontError: const SocketException('unused'),
          cameraError: camera,
        ),
        onResult: (_) {},
      );

      await _takeFrontPhoto(tester);

      expect(
        tester.widget<AppSnackBarView>(find.byType(AppSnackBarView)).message,
        message,
      );
    });
  }
}
