import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A photo of a food package taken in the product editor.
@immutable
class ProductPhoto {
  /// Creates a photo.
  const new({required this.path, required this.bytes, required this.mimeType});

  /// Local file of the photo.
  final String path;

  /// Image data.
  final Uint8List bytes;

  /// Image type, such as "image/jpeg".
  final String mimeType;
}

/// What the front of a food package shows.
@immutable
class ProductFrontDetails {
  /// Creates the details.
  const new({
    required this.name,
    this.brand,
    this.quantityLabel,
    this.pieceCount,
    this.barcode,
  });

  /// Product name without the brand.
  final String name;

  /// Brand, when printed.
  final String? brand;

  /// Net quantity with unit as printed, such as "500 g".
  final String? quantityLabel;

  /// Number of pieces or portions printed on the pack.
  final int? pieceCount;

  /// Barcode digits the AI read, when every digit was certain.
  final String? barcode;
}

/// Package photos whose upload has started.
@immutable
class ProductPhotoUpload {
  /// Creates the upload.
  const new({required this.frontAddress, required this.done});

  /// Storage address of the front photo, or null without one.
  final String? frontAddress;

  /// Completes when the photos are stored; fails when the front photo
  /// could not be stored.
  final Future<void> done;
}
