import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'firestore_kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_data_providers.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_image_store.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

class _FakeKitchenUtensilImageStore implements KitchenUtensilImageStore {
  @override
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    return path;
  }

  @override
  Future<bool> deleteImage(String path) async {
    return true;
  }

  @override
  Future<String?> downloadUrl(String path) async {
    return 'https://example.test/$path';
  }
}

void main() {
  tearDown(resetFirebaseStorageProviderDebugHooks);

  test('image store provider falls back to unavailable image store', () async {
    debugFirebaseStorageInstanceGetter = () => throw StateError('offline');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final imageStore = container.read(kitchenUtensilImageStoreProvider);

    expect(
      await imageStore.uploadBytes(
        path: 'households/household-1/kitchen_utensils/pot-1/images/one.jpg',
        bytes: Uint8List.fromList(<int>[1]),
      ),
      isNull,
    );
    expect(await imageStore.deleteImage('path.jpg'), isFalse);
    expect(await imageStore.downloadUrl('path.jpg'), isNull);
  });

  test(
    'repository reads empty and refuses writes without a household',
    () async {
      final container = ProviderContainer(
        overrides: [
          householdDataScopeProvider.overrideWithValue(null),
          kitchenUtensilImageStoreProvider.overrideWithValue(
            _FakeKitchenUtensilImageStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(kitchenUtensilRepositoryProvider);

      expect(repository, isA<FirestoreKitchenUtensilRepository>());
      expect(await repository.readAll(), isEmpty);
      expect(await repository.watchAll().first, isEmpty);
      expect(
        await repository.save(
          KitchenUtensil(
            id: 'pot-1',
            name: 'Pot',
            weightGrams: 420,
            createdAt: DateTime.parse('2026-04-01T10:00:00Z'),
            updatedAt: DateTime.parse('2026-04-01T10:00:00Z'),
          ),
        ),
        isFalse,
      );
      expect(await repository.delete('pot-1'), isFalse);
    },
  );
}
