import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'firestore_kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_data_providers.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_image_store.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_store.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const _FakeInventoryUserSession({required this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeKitchenUtensilStore implements KitchenUtensilStore {
  @override
  Future<List<KitchenUtensilDocument>> readAll({
    required String userId,
  }) async {
    return const <KitchenUtensilDocument>[];
  }

  @override
  Stream<List<KitchenUtensilDocument>> watchAll({required String userId}) {
    return const Stream<List<KitchenUtensilDocument>>.empty();
  }

  @override
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  }) async {
    return true;
  }

  @override
  Future<bool> delete({
    required String userId,
    required String utensilId,
  }) async {
    return true;
  }
}

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
  tearDown(() {
    resetFirebaseFirestoreProviderDebugHooks();
    resetFirebaseStorageProviderDebugHooks();
  });

  test('user session provider reads household owner id', () {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => const Stream<User?>.empty(),
        ),
        householdDataOwnerUserIdProvider.overrideWith((ref) => 'owner-1'),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(kitchenUtensilUserSessionProvider).currentUserId,
      'owner-1',
    );
  });

  test('store provider falls back to unavailable store', () async {
    debugFirebaseFirestoreInstanceGetter = () => throw StateError('offline');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final store = container.read(kitchenUtensilStoreProvider);

    expect(await store.readAll(userId: 'owner-1'), isEmpty);
    expect(
      await store.upsert(
        userId: 'owner-1',
        utensilId: 'pot-1',
        data: const <String, dynamic>{},
      ),
      isFalse,
    );
    expect(
      await store.delete(userId: 'owner-1', utensilId: 'pot-1'),
      isFalse,
    );
  });

  test('image store provider falls back to unavailable image store', () async {
    debugFirebaseStorageInstanceGetter = () => throw StateError('offline');
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final imageStore = container.read(kitchenUtensilImageStoreProvider);

    expect(
      await imageStore.uploadBytes(
        path: 'users/owner-1/kitchen_utensils/pot-1/images/one.jpg',
        bytes: Uint8List.fromList(<int>[1]),
      ),
      isNull,
    );
    expect(await imageStore.deleteImage('path.jpg'), isFalse);
    expect(await imageStore.downloadUrl('path.jpg'), isNull);
  });

  test('repository provider composes firestore repository from providers', () {
    final container = ProviderContainer(
      overrides: [
        kitchenUtensilUserSessionProvider.overrideWithValue(
          const _FakeInventoryUserSession(currentUserId: 'owner-1'),
        ),
        sessionShutdownSignalProvider.overrideWithValue(
          SessionShutdownSignal(),
        ),
        kitchenUtensilStoreProvider.overrideWithValue(
          _FakeKitchenUtensilStore(),
        ),
        kitchenUtensilImageStoreProvider.overrideWithValue(
          _FakeKitchenUtensilImageStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(kitchenUtensilRepositoryProvider),
      isA<FirestoreKitchenUtensilRepository>(),
    );
  });
}
