import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:yamt/core/debug/debug_log.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const int _maxReceiptAnalysisBytes = 12 * 1024 * 1024;
const int _maxReceiptImageEdge = 1800;
const int _receiptImageJpegQuality = 82;
const String _jpegMimeType = 'image/jpeg';
const String _receiptInputLogName = 'ReceiptAnalysisInput';
const List<({int maxEdge, int quality})> _receiptImageEncodeAttempts = [
  (maxEdge: _maxReceiptImageEdge, quality: _receiptImageJpegQuality),
  (maxEdge: 1600, quality: 74),
  (maxEdge: 1400, quality: 68),
  (maxEdge: 1200, quality: 60),
  (maxEdge: 1000, quality: 55),
];
const Set<String> _unsupportedReceiptImageMimeTypes = <String>{
  'image/heic',
  'image/heif',
  'image/heic-sequence',
  'image/heif-sequence',
};

/// Build receipt template inputs.
Future<Map<String, Object?>> buildReceiptTemplateInputs(
  ReceiptInputSelection selection,
) async {
  Stopwatch? stopwatch;
  assert(() {
    stopwatch = startDebugStopwatch();
    return true;
  }(), 'Start debug receipt input timing.');
  _throwIfUnsupportedReceiptImageMimeType(selection.mimeType);
  final sourceBytes = await _resolveSelectionBytes(selection);
  _throwIfReceiptInputTooLarge(sourceBytes.length);
  final input = await _optimizeAnalysisInput(
    bytes: sourceBytes,
    mimeType: selection.mimeType,
  );
  _throwIfReceiptInputTooLarge(input.bytes.length);
  final base64Data = base64Encode(input.bytes);
  assert(() {
    _debugLogPreparedInput(
      selection: selection,
      sourceByteLength: sourceBytes.length,
      input: input,
      elapsed: stopDebugStopwatch(stopwatch),
    );
    return true;
  }(), 'Log debug receipt input timing.');

  return <String, Object?>{
    'mimeType': input.mimeType,
    'imageData': base64Data,
  };
}

Future<Uint8List> _resolveSelectionBytes(
  ReceiptInputSelection selection,
) async {
  if (selection.hasEmbeddedBytes) {
    return selection.bytes;
  }

  final filePath = selection.filePath;
  if (filePath == null || filePath.isEmpty) {
    throw const _ReceiptInputBytesMissingException(
      'Receipt input has no bytes and no file path.',
    );
  }
  final file = XFile(filePath);
  final fileLength = await file.length();
  _throwIfReceiptInputTooLarge(fileLength);
  return file.readAsBytes();
}

void _throwIfReceiptInputTooLarge(int byteLength) {
  if (byteLength > _maxReceiptAnalysisBytes) {
    throw _ReceiptInputFileTooLargeException(byteLength);
  }
}

void _throwIfUnsupportedReceiptImageMimeType(String mimeType) {
  if (_isUnsupportedReceiptImageMimeType(mimeType)) {
    throw _ReceiptUnsupportedImageFormatException(mimeType);
  }
}

Future<_ReceiptAnalysisInput> _optimizeAnalysisInput({
  required Uint8List bytes,
  required String mimeType,
}) async {
  if (!_isOptimizableImageMimeType(mimeType)) {
    return _ReceiptAnalysisInput(bytes: bytes, mimeType: mimeType);
  }

  try {
    final result = await compute(
      _optimizeImageBytes,
      <String, Object?>{
        'bytes': bytes,
        'mimeType': mimeType,
      },
      debugLabel: 'receipt-image-optimize',
    );
    if (result['decodeFailed'] == true) {
      throw const _ReceiptInputImageDecodeException();
    }
    if (result['tooLarge'] == true) {
      final byteLength = result['byteLength'];
      throw _ReceiptInputFileTooLargeException(
        byteLength is int ? byteLength : bytes.length,
      );
    }
    final optimizedBytes = result['bytes'];
    final optimizedMimeType = result['mimeType'];
    if (optimizedBytes is! Uint8List || optimizedMimeType is! String) {
      return _ReceiptAnalysisInput(bytes: bytes, mimeType: mimeType);
    }
    return _ReceiptAnalysisInput(
      bytes: optimizedBytes,
      mimeType: optimizedMimeType,
      optimized: result['optimized'] == true,
    );
  } on _ReceiptInputImageDecodeException {
    rethrow;
  } on Object catch (error, stackTrace) {
    appLog(
      'Receipt image optimization failed; using original input.',
      name: _receiptInputLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return _ReceiptAnalysisInput(bytes: bytes, mimeType: mimeType);
  }
}

Map<String, Object?> _optimizeImageBytes(Map<String, Object?> input) {
  final bytes = input['bytes'];
  final mimeType = input['mimeType'];
  if (bytes is! Uint8List || mimeType is! String) {
    return input;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return <String, Object?>{
      'decodeFailed': true,
    };
  }

  final oriented = img.bakeOrientation(decoded);
  Uint8List? smallestEncoded;
  for (final attempt in _receiptImageEncodeAttempts) {
    final resized = _resizeForAnalysis(
      oriented,
      targetMaxEdge: attempt.maxEdge,
    );
    final encoded = img.encodeJpg(resized, quality: attempt.quality);
    if (smallestEncoded == null || encoded.length < smallestEncoded.length) {
      smallestEncoded = encoded;
    }

    if (encoded.length > _maxReceiptAnalysisBytes) {
      continue;
    }
    if (encoded.length >= bytes.length && identical(resized, oriented)) {
      return <String, Object?>{
        'bytes': bytes,
        'mimeType': mimeType,
        'optimized': false,
      };
    }

    return <String, Object?>{
      'bytes': encoded,
      'mimeType': _jpegMimeType,
      'optimized': true,
    };
  }

  if (bytes.length <= _maxReceiptAnalysisBytes) {
    return <String, Object?>{
      'bytes': bytes,
      'mimeType': mimeType,
      'optimized': false,
    };
  }

  return <String, Object?>{
    'tooLarge': true,
    'byteLength': smallestEncoded?.length ?? bytes.length,
  };
}

img.Image _resizeForAnalysis(img.Image image, {required int targetMaxEdge}) {
  final sourceMaxEdge = math.max(image.width, image.height);
  if (sourceMaxEdge <= targetMaxEdge) {
    return image;
  }

  final scale = targetMaxEdge / sourceMaxEdge;
  final width = math.max(1, (image.width * scale).round());
  final height = math.max(1, (image.height * scale).round());
  return img.copyResize(
    image,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
}

bool _isOptimizableImageMimeType(String mimeType) {
  final normalizedMimeType = _normalizedMimeType(mimeType);
  return normalizedMimeType.startsWith('image/') &&
      !_unsupportedReceiptImageMimeTypes.contains(normalizedMimeType);
}

bool _isUnsupportedReceiptImageMimeType(String mimeType) {
  return _unsupportedReceiptImageMimeTypes.contains(
    _normalizedMimeType(mimeType),
  );
}

String _normalizedMimeType(String mimeType) {
  return mimeType.split(';').first.trim().toLowerCase();
}

void _debugLogPreparedInput({
  required ReceiptInputSelection selection,
  required int sourceByteLength,
  required _ReceiptAnalysisInput input,
  required Duration elapsed,
}) {
  debugLog(
    'Prepared receipt AI input for ${selection.name} in '
    '${elapsed.inMilliseconds}ms '
    '($sourceByteLength -> ${input.bytes.length} bytes, '
    'mime: ${selection.mimeType} -> ${input.mimeType}, '
    'optimized: ${input.optimized}).',
    name: _receiptInputLogName,
  );
}

class _ReceiptAnalysisInput {
  const _ReceiptAnalysisInput({
    required this.bytes,
    required this.mimeType,
    this.optimized = false,
  });

  final Uint8List bytes;
  final String mimeType;
  final bool optimized;
}

class _ReceiptInputBytesMissingException implements Exception {
  const _ReceiptInputBytesMissingException(this.message);

  final String message;
}

class _ReceiptInputFileTooLargeException implements Exception {
  const _ReceiptInputFileTooLargeException(this.byteLength);

  final int byteLength;
}

class _ReceiptUnsupportedImageFormatException implements Exception {
  const _ReceiptUnsupportedImageFormatException(this.mimeType);

  final String mimeType;
}

class _ReceiptInputImageDecodeException implements Exception {
  const _ReceiptInputImageDecodeException();
}
