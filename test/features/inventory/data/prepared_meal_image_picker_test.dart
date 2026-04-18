import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';

const int _maxPreparedMealImageBytes = 350 * 1024;

void main() {
  test('optimizePreparedMealImageBytes downscales oversized images', () async {
    final originalImage = _createNoisyImage(width: 512, height: 512);
    final originalBytes = Uint8List.fromList(img.encodeBmp(originalImage));
    expect(originalBytes.length, greaterThan(_maxPreparedMealImageBytes));

    final optimizedBytes = await optimizePreparedMealImageBytes(originalBytes);
    final optimizedImage = img.decodeImage(optimizedBytes);

    expect(
      optimizedBytes.length,
      lessThanOrEqualTo(_maxPreparedMealImageBytes),
    );
    expect(optimizedImage, isNotNull);
    expect(optimizedImage!.width, lessThan(originalImage.width));
    expect(optimizedImage.height, lessThan(originalImage.height));
  });

  test('optimizePreparedMealImageBytes keeps small images untouched', () async {
    final originalImage = _createNoisyImage(width: 128, height: 128);
    final originalBytes = Uint8List.fromList(img.encodePng(originalImage));
    expect(originalBytes.length, lessThan(_maxPreparedMealImageBytes));

    final optimizedBytes = await optimizePreparedMealImageBytes(originalBytes);

    expect(optimizedBytes, orderedEquals(originalBytes));
  });

  test(
    'optimizePreparedMealImageBytes shrinks oversized dimensions '
    'even when bytes already fit',
    () async {
      final originalImage = img.Image(width: 2400, height: 1800);
      img.fill(originalImage, color: img.ColorRgb8(180, 120, 90));
      final originalBytes = Uint8List.fromList(img.encodeJpg(originalImage));
      expect(originalBytes.length, lessThan(_maxPreparedMealImageBytes));

      final optimizedBytes = await optimizePreparedMealImageBytes(
        originalBytes,
      );
      final optimizedImage = img.decodeImage(optimizedBytes);

      expect(optimizedImage, isNotNull);
      expect(optimizedImage!.width, lessThanOrEqualTo(1600));
      expect(optimizedImage.height, lessThanOrEqualTo(1600));
    },
  );

  test(
    'optimizePreparedMealImageBytes throws when image cannot fit into max size',
    () async {
      final originalImage = _createNoisyImage(width: 128, height: 128);
      final originalBytes = Uint8List.fromList(img.encodeBmp(originalImage));

      await expectLater(
        () => optimizePreparedMealImageBytes(originalBytes, maxBytes: 1),
        throwsA(
          isA<PreparedMealImagePickerException>().having(
            (error) => error.code,
            'code',
            PreparedMealImagePickerErrorCodes.imageTooLarge,
          ),
        ),
      );
    },
  );

  test(
    'optimizePreparedMealImageBytes surfaces isolate runner failures',
    () async {
      final originalImage = _createNoisyImage(width: 256, height: 256);
      final originalBytes = Uint8List.fromList(img.encodeBmp(originalImage));

      await expectLater(
        () => optimizePreparedMealImageBytes(
          originalBytes,
          maxBytes: 1,
          optimizationRunner: (_) async => throw StateError('isolate-boom'),
        ),
        throwsA(
          isA<PreparedMealImagePickerException>().having(
            (error) => error.code,
            'code',
            PreparedMealImagePickerErrorCodes.imageOptimizationFailed,
          ),
        ),
      );
    },
  );

  test(
    'optimizePreparedMealImageBytes rejects invalid isolate payloads',
    () async {
      final originalImage = _createNoisyImage(width: 256, height: 256);
      final originalBytes = Uint8List.fromList(img.encodeBmp(originalImage));

      await expectLater(
        () => optimizePreparedMealImageBytes(
          originalBytes,
          maxBytes: 1,
          optimizationRunner: (_) async => <String, Object?>{},
        ),
        throwsA(
          isA<PreparedMealImagePickerException>().having(
            (error) => error.code,
            'code',
            PreparedMealImagePickerErrorCodes.imageOptimizationFailed,
          ),
        ),
      );
    },
  );
}

img.Image _createNoisyImage({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  var seed = 0x12345678;

  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      seed = _nextSeed(seed);
      final red = seed & 0xFF;
      seed = _nextSeed(seed);
      final green = seed & 0xFF;
      seed = _nextSeed(seed);
      final blue = seed & 0xFF;
      image.setPixelRgb(x, y, red, green, blue);
    }
  }

  return image;
}

int _nextSeed(int value) {
  return (value * 1664525 + 1013904223) & 0x7FFFFFFF;
}
