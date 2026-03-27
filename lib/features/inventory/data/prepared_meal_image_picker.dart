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
const int _cameraImageQuality = 72;
const int _initialJpegQuality = 88;
const int _minimumJpegQuality = 44;
const double _downscaleStep = 0.82;
const int _minimumImageDimension = 96;
const int _maxOptimizationPasses = 12;

class PreparedMealImagePickerException implements Exception {
  const PreparedMealImagePickerException(this.code);

  final String code;
}

abstract final class PreparedMealImagePickerErrorCodes {
  static const imageTooLarge = 'prepared_meal_image_too_large';
  static const imageOptimizationFailed =
      'prepared_meal_image_optimization_failed';
  static const cameraPickFailed = 'prepared_meal_camera_pick_failed';
  static const filePickFailed = 'prepared_meal_file_pick_failed';
}

typedef PreparedMealImageOptimizationRunner =
    Future<Map<String, Object?>> Function(Map<String, Object> message);

abstract interface class PreparedMealImagePicker {
  Future<Uint8List?> pickFromCamera();

  Future<Uint8List?> pickFromFile();

  bool get supportsCamera;
}

@riverpod
PreparedMealImagePicker preparedMealImagePicker(Ref ref) {
  return DevicePreparedMealImagePicker(
    imagePicker: ImagePicker(),
    filePicker: FilePicker.platform,
  );
}

class DevicePreparedMealImagePicker implements PreparedMealImagePicker {
  DevicePreparedMealImagePicker({
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
    } catch (error, stackTrace) {
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
        allowMultiple: false,
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
    } catch (error, stackTrace) {
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
    if (bytes.length > _maxPreparedMealImageBytes) {
      log(
        'Prepared meal image exceeds byte limit. '
        'Attempting optimization bytes=${bytes.length}.',
        name: 'PreparedMealImagePicker',
      );
      final optimizedBytes = await optimizePreparedMealImageBytes(bytes);
      log(
        'Prepared meal image optimization finished '
        'original=${bytes.length} optimized=${optimizedBytes.length}.',
        name: 'PreparedMealImagePicker',
      );
      return optimizedBytes;
    }
    return bytes;
  }
}

@visibleForTesting
Future<Uint8List> optimizePreparedMealImageBytes(
  Uint8List bytes, {
  int maxBytes = _maxPreparedMealImageBytes,
  PreparedMealImageOptimizationRunner optimizationRunner =
      _runPreparedMealImageOptimizationInIsolate,
}) async {
  if (bytes.length <= maxBytes) {
    return bytes;
  }

  final message = <String, Object>{
    'bytes': TransferableTypedData.fromList([bytes]),
    'maxBytes': maxBytes,
  };
  late final Map<String, Object?> result;
  try {
    result = await optimizationRunner(message);
  } on PreparedMealImagePickerException {
    rethrow;
  } catch (error, stackTrace) {
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
    final transferableBytes = message['bytes'] as TransferableTypedData;
    final maxBytes = message['maxBytes'] as int;
    final bytes = transferableBytes.materialize().asUint8List();
    final optimizedBytes = _optimizePreparedMealImageBytesSync(
      bytes,
      maxBytes: maxBytes,
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
}) {
  if (bytes.length <= maxBytes) {
    return bytes;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const PreparedMealImagePickerException(
      PreparedMealImagePickerErrorCodes.imageTooLarge,
    );
  }

  final preferJpeg = !decoded.hasAlpha;
  final initialScale = math.min(
    0.95,
    math.sqrt(maxBytes / bytes.length) * 0.98,
  );
  var currentWidth = math.max(
    _minimumImageDimension,
    (decoded.width * initialScale).round(),
  );
  var currentHeight = math.max(
    _minimumImageDimension,
    (decoded.height * initialScale).round(),
  );
  if (currentWidth == decoded.width && currentHeight == decoded.height) {
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
    if (encodedBytes.length <= maxBytes) {
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
