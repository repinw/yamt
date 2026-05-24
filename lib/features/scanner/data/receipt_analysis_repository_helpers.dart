import 'dart:convert';
import 'dart:developer' show log;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const int _maxReceiptAnalysisBytes = 12 * 1024 * 1024;
const int _maxReceiptImageEdge = 1800;
const int _receiptImageJpegQuality = 82;
const String _jpegMimeType = 'image/jpeg';
const String _receiptInputLogName = 'ReceiptAnalysisInput';

/// Build receipt template inputs.
Future<Map<String, Object?>> buildReceiptTemplateInputs(
  ReceiptInputSelection selection,
) async {
  final stopwatch = Stopwatch()..start();
  final sourceBytes = await _resolveSelectionBytes(selection);
  final input = await _optimizeAnalysisInput(
    bytes: sourceBytes,
    mimeType: selection.mimeType,
  );
  if (input.bytes.length > _maxReceiptAnalysisBytes) {
    throw _ReceiptInputFileTooLargeException(input.bytes.length);
  }
  final base64Data = base64Encode(input.bytes);
  stopwatch.stop();
  _debugLogPreparedInput(
    selection: selection,
    sourceByteLength: sourceBytes.length,
    input: input,
    elapsed: stopwatch.elapsed,
  );

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
  if (fileLength > _maxReceiptAnalysisBytes) {
    throw _ReceiptInputFileTooLargeException(fileLength);
  }
  return file.readAsBytes();
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
  } on Object catch (error, stackTrace) {
    log(
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
      'bytes': bytes,
      'mimeType': mimeType,
      'optimized': false,
    };
  }

  final oriented = img.bakeOrientation(decoded);
  final resized = _resizeForAnalysis(oriented);
  final encoded = Uint8List.fromList(
    img.encodeJpg(resized, quality: _receiptImageJpegQuality),
  );
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

img.Image _resizeForAnalysis(img.Image image) {
  final maxEdge = math.max(image.width, image.height);
  if (maxEdge <= _maxReceiptImageEdge) {
    return image;
  }

  final scale = _maxReceiptImageEdge / maxEdge;
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
  return mimeType.trim().toLowerCase().startsWith('image/');
}

void _debugLogPreparedInput({
  required ReceiptInputSelection selection,
  required int sourceByteLength,
  required _ReceiptAnalysisInput input,
  required Duration elapsed,
}) {
  assert(() {
    log(
      'Prepared receipt AI input for ${selection.name} in '
      '${elapsed.inMilliseconds}ms '
      '($sourceByteLength -> ${input.bytes.length} bytes, '
      'mime: ${selection.mimeType} -> ${input.mimeType}, '
      'optimized: ${input.optimized}).',
      name: _receiptInputLogName,
    );
    return true;
  }(), 'Receipt input timing log should run only in debug mode.');
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
