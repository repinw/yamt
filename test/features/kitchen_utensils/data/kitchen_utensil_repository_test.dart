import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'firestore_kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_image_store.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_store.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const _FakeInventoryUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeKitchenUtensilStore implements KitchenUtensilStore {
  List<KitchenUtensilDocument> documents = const <KitchenUtensilDocument>[];
  Exception? watchAllError;
  Map<String, dynamic>? lastUpsertData;
  String? lastUserId;
  String? lastUtensilId;
  bool shouldWriteSucceed = true;

  @override
  Future<List<KitchenUtensilDocument>> readAll({
    required String userId,
  }) async {
    lastUserId = userId;
    return documents;
  }

  @override
  Stream<List<KitchenUtensilDocument>> watchAll({
    required String userId,
  }) async* {
    lastUserId = userId;
    final error = watchAllError;
    if (error != null) {
      throw error;
    }
    yield documents;
  }

  @override
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  }) async {
    lastUserId = userId;
    lastUtensilId = utensilId;
    lastUpsertData = data;
    return shouldWriteSucceed;
  }

  @override
  Future<bool> delete({
    required String userId,
    required String utensilId,
  }) async {
    lastUserId = userId;
    lastUtensilId = utensilId;
    return shouldWriteSucceed;
  }
}

class _FakeKitchenUtensilImageStore implements KitchenUtensilImageStore {
  final deletedPaths = <String>[];
  String? lastUploadPath;
  String? uploadResultPath;

  @override
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    lastUploadPath = path;
    return uploadResultPath ?? path;
  }

  @override
  Future<bool> deleteImage(String path) async {
    deletedPaths.add(path);
    return true;
  }

  @override
  Future<String?> downloadUrl(String path) async {
    return 'https://example.test/$path';
  }
}

FirestoreKitchenUtensilRepository _repository({
  required InventoryUserSession session,
  required KitchenUtensilStore store,
  required KitchenUtensilImageStore imageStore,
  SessionShutdownSignal? sessionShutdownSignal,
}) {
  return FirestoreKitchenUtensilRepository(
    session: session,
    sessionShutdownSignal: sessionShutdownSignal ?? SessionShutdownSignal(),
    store: store,
    imageStore: imageStore,
  );
}

KitchenUtensil _utensil() {
  return KitchenUtensil(
    id: 'pot-1',
    name: 'Pot',
    weightGrams: 420,
    createdAt: DateTime.parse('2026-04-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-04-01T10:00:00Z'),
  );
}

void main() {
  test(
    'FirestoreKitchenUtensilStore upserts, watches, reads, and deletes',
    () async {
      final firestore = FakeFirebaseFirestore();
      final store = FirestoreKitchenUtensilStore(firestore: firestore);

      expect(
        await store.upsert(
          userId: 'owner-1',
          utensilId: 'pot-1',
          data: const {
            'id': 'pot-1',
            'name': 'Pot',
            'weight_grams': 420,
          },
        ),
        isTrue,
      );

      final watchedDocuments = await store.watchAll(userId: 'owner-1').first;
      final readDocuments = await store.readAll(userId: 'owner-1');

      expect(watchedDocuments.single.id, 'pot-1');
      expect(readDocuments.single.data['name'], 'Pot');
      expect(
        await store.delete(userId: 'owner-1', utensilId: 'pot-1'),
        isTrue,
      );
      expect(await store.readAll(userId: 'owner-1'), isEmpty);
    },
  );

  test(
    'readAll fills missing document id and skips invalid documents',
    () async {
      final store = _FakeKitchenUtensilStore()
        ..documents = const [
          KitchenUtensilDocument(
            id: 'pot-1',
            data: {
              'name': 'Pot',
              'weight_grams': 420,
              'created_at': '2026-04-01T10:00:00Z',
              'updated_at': '2026-04-01T10:00:00Z',
            },
          ),
          KitchenUtensilDocument(
            id: 'broken',
            data: {
              'id': 'broken',
              'weight_grams': 0,
              'created_at': '2026-04-01T10:00:00Z',
              'updated_at': '2026-04-01T10:00:00Z',
            },
          ),
          KitchenUtensilDocument(
            id: 'non-string-id',
            data: {
              'id': 123,
              'name': 'Corrupt',
              'weight_grams': 420,
              'created_at': '2026-04-01T10:00:00Z',
              'updated_at': '2026-04-01T10:00:00Z',
            },
          ),
        ];
      final repository = _repository(
        session: const _FakeInventoryUserSession(currentUserId: 'user-1'),
        store: store,
        imageStore: _FakeKitchenUtensilImageStore(),
      );

      final utensils = await repository.readAll();

      expect(utensils, hasLength(1));
      expect(utensils.single.id, 'pot-1');
      expect(store.lastUserId, 'user-1');
    },
  );

  test('save and delete delegate to household owner user id', () async {
    final store = _FakeKitchenUtensilStore();
    final repository = _repository(
      session: const _FakeInventoryUserSession(currentUserId: 'owner-1'),
      store: store,
      imageStore: _FakeKitchenUtensilImageStore(),
    );

    expect(await repository.save(_utensil()), isTrue);
    expect(store.lastUserId, 'owner-1');
    expect(store.lastUtensilId, 'pot-1');
    expect(store.lastUpsertData?['weight_grams'], 420);

    expect(await repository.delete('pot-1'), isTrue);
    expect(store.lastUtensilId, 'pot-1');
  });

  test('returns empty data and false writes without user', () async {
    final repository = _repository(
      session: const _FakeInventoryUserSession(),
      store: _FakeKitchenUtensilStore(),
      imageStore: _FakeKitchenUtensilImageStore(),
    );

    expect(await repository.readAll(), isEmpty);
    expect(await repository.save(_utensil()), isFalse);
    expect(await repository.delete('pot-1'), isFalse);
    expect(
      await repository.uploadImage(
        utensilId: 'pot-1',
        imageId: 'image-1',
        bytes: Uint8List.fromList(<int>[1]),
      ),
      isNull,
    );
  });

  test('uploadImage builds storage path and imageUrl resolves URL', () async {
    final imageStore = _FakeKitchenUtensilImageStore();
    final repository = _repository(
      session: const _FakeInventoryUserSession(currentUserId: 'owner-1'),
      store: _FakeKitchenUtensilStore(),
      imageStore: imageStore,
    );

    final path = await repository.uploadImage(
      utensilId: 'pot-1',
      imageId: 'image-1',
      bytes: Uint8List.fromList(<int>[1]),
    );

    expect(
      path,
      'users/owner-1/kitchen_utensils/pot-1/images/image-1.jpg',
    );
    expect(imageStore.lastUploadPath, path);
    expect(await repository.imageUrl(path!), 'https://example.test/$path');
    expect(await repository.deleteImage(path), isTrue);
    expect(imageStore.deletedPaths, [path]);
  });

  test('watchAll rethrows permission denied outside shutdown', () async {
    final store = _FakeKitchenUtensilStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = _repository(
      session: const _FakeInventoryUserSession(currentUserId: 'owner-1'),
      store: store,
      imageStore: _FakeKitchenUtensilImageStore(),
    );

    await expectLater(
      repository.watchAll().first,
      throwsA(isA<FirebaseException>()),
    );
  });

  test('watchAll returns empty during shutdown permission denied', () async {
    final signal = SessionShutdownSignal()..begin();
    final store = _FakeKitchenUtensilStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = _repository(
      session: const _FakeInventoryUserSession(currentUserId: 'owner-1'),
      store: store,
      imageStore: _FakeKitchenUtensilImageStore(),
      sessionShutdownSignal: signal,
    );

    await expectLater(repository.watchAll().first, completion(isEmpty));
  });
}
