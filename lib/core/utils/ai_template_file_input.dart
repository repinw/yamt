import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:yamt/core/utils/photo_jpeg.dart';

// A pixel cap instead of a side cap, so a long, narrow page keeps its width
// and the small print stays readable.
const _maxPhotoPixels = 4000000;
const _maxPhotoSide = 6000;
const _shrinkableImageTypes = {'image/jpeg', 'image/png'};

/// The photo or PDF at [path] as a Firebase AI template input
/// (`{mimeType, data}`). JPEG and PNG photos shrink to a JPEG first, so
/// full-size scans of several pages overflow neither the request nor the
/// memory. Throws an [ArgumentError] for a file that is neither an image nor
/// a PDF.
Future<Map<String, Object?>> aiTemplateFileInput(String path) async {
  final mimeType = lookupMimeType(path);
  if (mimeType == null ||
      !(mimeType.startsWith('image/') || mimeType == 'application/pdf')) {
    throw ArgumentError.value(path, 'path', 'Unsupported AI input file');
  }
  final bytes = await File(path).readAsBytes();
  if (!_shrinkableImageTypes.contains(mimeType)) {
    return {'mimeType': mimeType, 'data': base64Encode(bytes)};
  }
  try {
    final jpeg = await compute(
      (bytes) => cleanPhotoJpeg(
        bytes,
        maxSide: _maxPhotoSide,
        maxPixels: _maxPhotoPixels,
      ),
      bytes,
    );
    return {'mimeType': 'image/jpeg', 'data': base64Encode(jpeg)};
  } on Object catch (error, stackTrace) {
    // The AI may still read what the image package cannot decode.
    log(
      'Could not shrink a photo; sending it as it is.',
      name: 'AiTemplateFileInput',
      error: error,
      stackTrace: stackTrace,
    );
    return {'mimeType': mimeType, 'data': base64Encode(bytes)};
  }
}
