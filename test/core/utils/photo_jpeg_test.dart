import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yamt/core/utils/photo_jpeg.dart';

void main() {
  test('cleanPhotoJpeg drops the metadata and turns the pixels', () {
    final photo = img.Image(width: 4000, height: 3000);
    photo.exif.imageIfd['Model'] = img.IfdValueAscii('Phone 9');
    photo.exif.imageIfd.orientation = 6;
    photo.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');

    final cleaned = img.decodeJpg(cleanPhotoJpeg(img.encodeJpg(photo)))!;

    expect((cleaned.width, cleaned.height), (1200, 1600));
    expect(cleaned.exif.isEmpty, isTrue);
  });

  test('cleanPhotoJpeg keeps a narrow photo wide under a pixel cap', () {
    final photo = img.Image(width: 1000, height: 5000);

    final cleaned = img.decodeJpg(
      cleanPhotoJpeg(img.encodeJpg(photo), maxSide: 6000, maxPixels: 4000000),
    )!;

    expect((cleaned.width, cleaned.height), (894, 4472));
  });

  test('cleanPhotoJpeg rejects bytes that are no image', () {
    expect(
      () => cleanPhotoJpeg(Uint8List.fromList(List<int>.filled(256, 7))),
      throwsFormatException,
    );
  });
}
