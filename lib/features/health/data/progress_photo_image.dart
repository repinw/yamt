import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Longest side in pixels of a stored progress photo.
const progressPhotoMaxSide = 1600;

const _jpegQuality = 85;

/// Re-encodes [imageBytes] as a JPEG without metadata.
///
/// The EXIF block with location, device, and time is dropped after its
/// rotation is applied to the pixels, and the long side shrinks to 1600
/// pixels. Throws a [FormatException] for bytes that are no image.
Uint8List cleanProgressPhoto(Uint8List imageBytes) {
  final decoded = img.findDecoderForData(imageBytes)?.decode(imageBytes);
  if (decoded == null) {
    throw const FormatException('The progress photo is no image.');
  }
  final upright = img.bakeOrientation(decoded);
  final scale = progressPhotoMaxSide / math.max(upright.width, upright.height);
  final sized = scale >= 1
      ? upright
      : img.copyResize(
          upright,
          width: (upright.width * scale).round(),
          height: (upright.height * scale).round(),
        );
  return img.encodeJpg(sized..exif = img.ExifData(), quality: _jpegQuality);
}
