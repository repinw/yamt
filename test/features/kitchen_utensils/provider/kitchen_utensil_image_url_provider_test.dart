import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensil_image_url_provider.dart';

class _FakeKitchenUtensilRepository implements KitchenUtensilRepository {
  @override
  Stream<List<KitchenUtensil>> watchAll() {
    return const Stream<List<KitchenUtensil>>.empty();
  }

  @override
  Future<List<KitchenUtensil>> readAll() async {
    return const <KitchenUtensil>[];
  }

  @override
  Future<bool> save(KitchenUtensil utensil) async {
    return true;
  }

  @override
  Future<bool> delete(String utensilId) async {
    return true;
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    return null;
  }

  @override
  Future<bool> deleteImage(String imageStoragePath) async {
    return true;
  }

  @override
  Future<String?> imageUrl(String imageStoragePath) async {
    return 'https://example.test/$imageStoragePath';
  }
}

void main() {
  test('kitchenUtensilImageUrlProvider resolves repository URL', () async {
    final container = ProviderContainer(
      overrides: [
        kitchenUtensilRepositoryProvider.overrideWithValue(
          _FakeKitchenUtensilRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final url = await container.read(
      kitchenUtensilImageUrlProvider('users/owner/pot.jpg').future,
    );

    expect(url, 'https://example.test/users/owner/pot.jpg');
  });
}
