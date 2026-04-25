// Image picker is reached through provider wiring and widget tests.
// ignore_for_file: unreachable_from_main

import 'dart:developer' show log;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prepared_meal_image_picker.g.dart';

const int _maxPreparedMealImageBytes = 350 * 1024;
const double _cameraMaxWidth = 1600;
const double _cameraMaxHeight = 1600;
const int _normalizedImageMaxWidth = 1600;
const int _normalizedImageMaxHeight = 1600;
const int _cameraImageQuality = 72;
const int _initialJpegQuality = 88;
const int _minimumJpegQuality = 44;
const double _downscaleStep = 0.82;
const int _minimumImageDimension = 96;
const int _maxOptimizationPasses = 12;

/// Defines prepared meal image picker exception.
class PreparedMealImagePickerException implements Exception {
  /// The prepared meal image picker exception.
  const PreparedMealImagePickerException(this.code);

  /// The code.
  final String code;
}

/// Defines prepared meal image picker error codes.
abstract final class PreparedMealImagePickerErrorCodes {
  /// The image too large.
  static const imageTooLarge = 'prepared_meal_image_too_large';

  /// The image optimization failed.
  static const imageOptimizationFailed =
      'prepared_meal_image_optimization_failed';

  /// The camera pick failed.
  static const cameraPickFailed = 'prepared_meal_camera_pick_failed';

  /// The file pick failed.
  static const filePickFailed = 'prepared_meal_file_pick_failed';
}

/// Defines prepared meal image picker.
abstract interface class PreparedMealImagePicker {
  /// Pick from camera.
  Future<Uint8List?> pickFromCamera();

  /// Pick from file.
  Future<Uint8List?> pickFromFile();

  /// Whether camera.
  bool get supportsCamera;
}

/// Prepared meal image picker.
@Riverpod(dependencies: [])
PreparedMealImagePicker preparedMealImagePicker(Ref ref) {
  return _DevicePreparedMealImagePicker(
    imagePicker: ImagePicker(),
    filePicker: FilePicker.platform,
  );
}

class _DevicePreparedMealImagePicker implements PreparedMealImagePicker {
  _DevicePreparedMealImagePicker({
    required ImagePicker imagePicker,
    required FilePicker filePicker,
  }) : _imagePicker = imagePicker,
       _filePicker = filePicker;

  final ImagePicker _imagePicker;
  final FilePicker _filePicker;

  @override
  bool get supportsCamera {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<Uint8List?> pickFromCamera() async {
    if (!supportsCamera) {
      return null;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: _cameraImageQuality,
        maxWidth: _cameraMaxWidth,
        maxHeight: _cameraMaxHeight,
      );
      if (image == null) {
        return null;
      }
      return _prepareBytes(await image.readAsBytes());
    } on PreparedMealImagePickerException {
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to pick prepared meal image from camera.',
        name: 'PreparedMealImagePicker',
        error: error,
        stackTrace: stackTrace,
      );
      throw const PreparedMealImagePickerException(
        PreparedMealImagePickerErrorCodes.cameraPickFailed,
      );
    }
  }

  @override
  Future<Uint8List?> pickFromFile() async {
    try {
      final result = await _filePicker.pickFiles(
        withData: true,
        type: FileType.image,
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await XFile(file.path!).readAsBytes());
      if (bytes == null) {
        throw const PreparedMealImagePickerException(
          PreparedMealImagePickerErrorCodes.filePickFailed,
        );
      }
      return _prepareBytes(bytes);
    } on PreparedMealImagePickerException {
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to pick prepared meal image from file.',
        name: 'PreparedMealImagePicker',
        error: error,
        stackTrace: stackTrace,
      );
      throw const PreparedMealImagePickerException(
        PreparedMealImagePickerErrorCodes.filePickFailed,
      );
    }
  }

  Future<Uint8List> _prepareBytes(Uint8List bytes) async {
    return optimizePreparedMealImageBytes(bytes);
  }
}

/// Optimize prepared meal image bytes.
@visibleForTesting
Future<Uint8List> optimizePreparedMealImageBytes(
  Uint8List bytes, {
  int maxBytes = _maxPreparedMealImageBytes,
  int maxWidth = _normalizedImageMaxWidth,
  int maxHeight = _normalizedImageMaxHeight,
  Future<Map<String, Object?>> Function(Map<String, Object> message)
      optimizationRunner =
      _runPreparedMealImageOptimizationInIsolate,
}) async {
  final message = <String, Object>{
    'bytes': TransferableTypedData.fromList([bytes]),
    'maxBytes': maxBytes,
    'maxWidth': maxWidth,
    'maxHeight': maxHeight,
  };
  late final Map<String, Object?> result;
  try {
    result = await optimizationRunner(message);
  } on PreparedMealImagePickerException {
    rethrow;
  } on Object catch (error, stackTrace) {
    log(
      'Prepared meal image optimization isolate failed.',
      name: 'PreparedMealImagePicker',
      error: error,
      stackTrace: stackTrace,
    );
    throw const PreparedMealImagePickerException(
      PreparedMealImagePickerErrorCodes.imageOptimizationFailed,
    );
  }

  final errorCode = result['errorCode'] as String?;
  if (errorCode != null) {
    throw PreparedMealImagePickerException(errorCode);
  }

  final optimizedBytes = result['bytes'] as TransferableTypedData?;
  if (optimizedBytes == null) {
    throw const PreparedMealImagePickerException(
      PreparedMealImagePickerErrorCodes.imageOptimizationFailed,
    );
  }

  return optimizedBytes.materialize().asUint8List();
}

Future<Map<String, Object?>> _runPreparedMealImageOptimizationInIsolate(
  Map<String, Object> message,
) {
  return compute(_optimizePreparedMealImageBytesInIsolate, message);
}

@pragma('vm:entry-point')
Map<String, Object?> _optimizePreparedMealImageBytesInIsolate(
  Map<String, Object> message,
) {
  try {
    final transferableBytes = message['bytes']! as TransferableTypedData;
    final maxBytes = message['maxBytes']! as int;
    final maxWidth = message['maxWidth']! as int;
    final maxHeight = message['maxHeight']! as int;
    final bytes = transferableBytes.materialize().asUint8List();
    final optimizedBytes = _optimizePreparedMealImageBytesSync(
      bytes,
      maxBytes: maxBytes,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return <String, Object?>{
      'bytes': TransferableTypedData.fromList([optimizedBytes]),
    };
  } on PreparedMealImagePickerException catch (error) {
    return <String, Object?>{'errorCode': error.code};
  }
}

Uint8List _optimizePreparedMealImageBytesSync(
  Uint8List bytes, {
  required int maxBytes,
  required int maxWidth,
  required int maxHeight,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    if (bytes.length <= maxBytes) {
      return bytes;
    }
    throw const PreparedMealImagePickerException(
      PreparedMealImagePickerErrorCodes.imageTooLarge,
    );
  }

  final needsDimensionResize =
      decoded.width > maxWidth || decoded.height > maxHeight;
  if (!needsDimensionResize && bytes.length <= maxBytes) {
    return bytes;
  }

  final preferJpeg = !decoded.hasAlpha;
  final dimensionScale = math.min(
    1,
    math.min(maxWidth / decoded.width, maxHeight / decoded.height),
  );
  final byteScale = bytes.length <= maxBytes
      ? 1.0
      : math.min(0.95, math.sqrt(maxBytes / bytes.length) * 0.98);
  final initialScale = math.min(dimensionScale, byteScale);
  var currentWidth = math.max(
    _minimumImageDimension,
    math.min(decoded.width, (decoded.width * initialScale).round()),
  );
  var currentHeight = math.max(
    _minimumImageDimension,
    math.min(decoded.height, (decoded.height * initialScale).round()),
  );
  if ((needsDimensionResize || bytes.length > maxBytes) &&
      currentWidth == decoded.width &&
      currentHeight == decoded.height) {
    currentWidth = math.max(
      _minimumImageDimension,
      (decoded.width * _downscaleStep).round(),
    );
    currentHeight = math.max(
      _minimumImageDimension,
      (decoded.height * _downscaleStep).round(),
    );
  }
  var currentJpegQuality = _initialJpegQuality;

  for (var attempt = 0; attempt < _maxOptimizationPasses; attempt += 1) {
    final needsResize =
        currentWidth != decoded.width || currentHeight != decoded.height;
    final workingImage = needsResize
        ? img.copyResize(decoded, width: currentWidth, height: currentHeight)
        : decoded;
    final encodedBytes = _encodePreparedMealImage(
      workingImage,
      preferJpeg: preferJpeg,
      jpegQuality: currentJpegQuality,
    );
    if (encodedBytes.length <= maxBytes &&
        workingImage.width <= maxWidth &&
        workingImage.height <= maxHeight) {
      return Uint8List.fromList(encodedBytes);
    }

    if (preferJpeg && currentJpegQuality > _minimumJpegQuality) {
      currentJpegQuality = math.max(
        _minimumJpegQuality,
        currentJpegQuality - 12,
      );
      continue;
    }

    final nextWidth = math.max(
      _minimumImageDimension,
      (currentWidth * _downscaleStep).round(),
    );
    final nextHeight = math.max(
      _minimumImageDimension,
      (currentHeight * _downscaleStep).round(),
    );
    if (nextWidth == currentWidth && nextHeight == currentHeight) {
      break;
    }
    currentWidth = nextWidth;
    currentHeight = nextHeight;
  }

  throw const PreparedMealImagePickerException(
    PreparedMealImagePickerErrorCodes.imageTooLarge,
  );
}

List<int> _encodePreparedMealImage(
  img.Image image, {
  required bool preferJpeg,
  required int jpegQuality,
}) {
  if (preferJpeg) {
    return img.encodeJpg(image, quality: jpegQuality);
  }
  return img.encodePng(image);
}
