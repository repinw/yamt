import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

part 'product_photo_repository.g.dart';

/// Firebase AI server prompt template that reads the front of a package.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const productFrontTemplateId = 'product-front-template';

const _requestTimeout = Duration(seconds: 60);
const _maxPhotoWidth = 1600.0;
const _photoQuality = 80;
const _uuid = Uuid();

/// Runs [productFrontTemplateId] with template [inputs] and returns the
/// response text.
typedef ProductFrontTemplateClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Returns the raw value of a product barcode in the image at a path, or
/// null without one.
typedef ProductBarcodeImageReader = Future<String?> Function(String path);

/// Product photo repository.
@riverpod
ProductPhotoRepository productPhotoRepository(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return ProductPhotoRepository(
    imagePicker: ImagePicker(),
    storage: ref.watch(firebaseStorageProvider),
    ownerId: ref.watch(authStateChangesProvider).asData?.value?.uid,
    templateClient: (inputs) async {
      final response = await model
          .generateContent(productFrontTemplateId, inputs: inputs)
          .timeout(_requestTimeout);
      return response.text;
    },
    barcodeReader: _readBarcodeWithScanner,
  );
}

Future<String?> _readBarcodeWithScanner(String path) async {
  final controller = MobileScannerController(autoStart: false);
  try {
    final capture = await controller.analyzeImage(
      path,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
    return capture?.barcodes.firstOrNull?.rawValue;
  } finally {
    await controller.dispose();
  }
}

/// Takes photos of food packages, reads their front and barcode, and stores
/// them as shared product images in Firebase Storage.
class ProductPhotoRepository {
  /// Creates a product photo repository.
  new({
    required this._imagePicker,
    required this._storage,
    required this._ownerId,
    required this._templateClient,
    required this._barcodeReader,
  });

  final ImagePicker _imagePicker;
  final FirebaseStorage? _storage;
  final String? _ownerId;
  final ProductFrontTemplateClient _templateClient;
  final ProductBarcodeImageReader _barcodeReader;

  /// Takes a photo with the camera. Returns null when the user cancels.
  ///
  /// Throws [ProductPhotoCameraUnsupportedException] on devices without a
  /// camera flow.
  Future<ProductPhoto?> loadCameraPhoto() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const ProductPhotoCameraUnsupportedException();
    }
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxPhotoWidth,
      imageQuality: _photoQuality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return ProductPhoto(
      path: file.path,
      bytes: bytes,
      mimeType: lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg',
    );
  }

  /// Returns the product barcode in [photo], or null when the scanner finds
  /// none that is valid.
  Future<String?> loadBarcode(ProductPhoto photo) async {
    final barcode = normalizeBarcode(await _barcodeReader(photo.path) ?? '');
    return isSupportedBarcode(barcode) ? barcode : null;
  }

  /// Reads name, brand, package size, and barcode from a photo of the
  /// package front.
  ///
  /// Throws a [ProductFrontException] when the photo shows no package or
  /// the name is not readable, and a [FormatException] on a broken answer.
  Future<ProductFrontDetails> loadFrontDetails(ProductPhoto photo) async {
    final text = await _templateClient({
      'mimeType': photo.mimeType,
      'imageData': base64Encode(photo.bytes),
    });
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty product front response');
    }
    final json = jsonDecode(text) as Map<String, dynamic>;
    switch (json['status']) {
      case 'not_product':
        throw const ProductFrontNotProductException();
      case 'unreadable':
        throw const ProductFrontUnreadableException();
    }
    final name = (json['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw const ProductFrontUnreadableException();
    }
    // Unlike the scanner, the AI can misread a digit; the check digit
    // catches that.
    final barcode = normalizeBarcode(json['barcode'] as String? ?? '');
    final hasValidBarcode =
        isSupportedBarcode(barcode) && isValidGtinChecksum(barcode);
    return ProductFrontDetails(
      name: name,
      brand: _text(json['brand']),
      quantityLabel: _text(json['quantity_label']),
      pieceCount: json['piece_count'] as int?,
      barcode: hasValidBarcode ? barcode : null,
    );
  }

  /// Stores [front] and [nutritionTable] as shared product images and
  /// returns the address of the front photo, or null without one.
  ///
  /// Other users see the front photo as the product image. Both photos
  /// carry the barcode and the name, so they can be checked later. Throws a
  /// [StateError] when signed out.
  Future<String?> saveProductPhotos({
    required ProductPhoto? front,
    required ProductPhoto? nutritionTable,
    required String barcode,
    required String name,
  }) async {
    final storage = _storage;
    final ownerId = _ownerId;
    if (storage == null || ownerId == null) {
      throw StateError('Product photos need a signed-in user.');
    }
    final folder = storage.ref('product_images/$ownerId/${_uuid.v4()}');
    Future<String> upload(ProductPhoto photo, String kind) async {
      final ref = folder.child('$kind.jpg');
      await ref.putData(
        photo.bytes,
        SettableMetadata(
          contentType: photo.mimeType,
          customMetadata: {'kind': kind, 'barcode': barcode, 'name': name},
        ),
      );
      return await ref.getDownloadURL();
    }

    if (nutritionTable != null) {
      await upload(nutritionTable, 'nutrition_table');
    }
    return front == null ? null : await upload(front, 'front');
  }

  static String? _text(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
