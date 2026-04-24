import 'dart:typed_data';

import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';

class FakePreparedMealImagePicker implements PreparedMealImagePicker {
  FakePreparedMealImagePicker({
    this.cameraBytes,
    this.fileBytes,
    this.cameraException,
    this.fileException,
    this.supportsCamera = false,
  });

  final Uint8List? cameraBytes;
  final Uint8List? fileBytes;
  final Exception? cameraException;
  final Exception? fileException;

  @override
  final bool supportsCamera;

  int cameraPickCount = 0;
  int filePickCount = 0;

  @override
  Future<Uint8List?> pickFromCamera() async {
    cameraPickCount += 1;
    final exception = cameraException;
    if (exception != null) {
      throw exception;
    }
    return _copyBytes(cameraBytes);
  }

  @override
  Future<Uint8List?> pickFromFile() async {
    filePickCount += 1;
    final exception = fileException;
    if (exception != null) {
      throw exception;
    }
    return _copyBytes(fileBytes);
  }

  Uint8List? _copyBytes(Uint8List? bytes) {
    return bytes == null ? null : Uint8List.fromList(bytes);
  }
}

Uint8List tinyPreparedMealPngBytes() {
  return Uint8List.fromList(const <int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1f,
    0x15,
    0xc4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0a,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9c,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0d,
    0x0a,
    0x2d,
    0xb4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4e,
    0x44,
    0xae,
    0x42,
    0x60,
    0x82,
  ]);
}
