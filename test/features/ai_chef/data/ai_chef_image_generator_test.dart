import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';

void main() {
  test('generate throws when image generation times out', () {
    final generator = AiChefImageGenerator(
      imageBytesClient: (_) =>
          Future<Uint8List?>.error(TimeoutException('image timed out')),
    );

    expect(
      generator.generate('tomato pasta'),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('generate throws when the image model gives no picture', () {
    final generator = AiChefImageGenerator(imageBytesClient: (_) async => null);

    expect(generator.generate('tomato pasta'), throwsStateError);
  });

  test('generate gives the bytes for the prompt', () async {
    String? asked;
    final generator = AiChefImageGenerator(
      imageBytesClient: (prompt) async {
        asked = prompt;
        return Uint8List.fromList([1, 2, 3]);
      },
    );

    expect(await generator.generate('tomato pasta'), [1, 2, 3]);
    expect(asked, 'tomato pasta');
  });
}
