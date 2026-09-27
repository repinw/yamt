import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('product image Storage rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('storage.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('every signed-in user reads the shared product images', () {
      expect(
        compactRules,
        contains(
          'match /product_images/{uid}/{photoId}/{fileName} { '
          'allow read: if isSignedIn();',
        ),
      );
    });

    test('only the uploader creates photos in their own folder', () {
      expect(
        compactRules,
        contains(
          'allow create: if isSignedIn() && request.auth.uid == uid '
          '&& isProductImage();',
        ),
      );
      expect(
        compactRules,
        contains(
          'return request.resource.size < 2 * 1024 * 1024 '
          "&& request.resource.contentType.matches('image/.*');",
        ),
      );
    });

    test('nobody changes or deletes a product image from the app', () {
      expect(
        compactRules,
        contains('isProductImage(); allow update, delete: if false; }'),
      );
    });
  });
}
