import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_image_store.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_store.dart';

const _dataProviderLogName = 'KitchenUtensilDataProviders';

/// Current household-scoped user session for kitchen utensils.
final kitchenUtensilUserSessionProvider = Provider<InventoryUserSession>((ref) {
  ref.watch(authStateChangesProvider);
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  return _CurrentKitchenUtensilUserSession(currentUserId: currentUserId);
});

/// Firestore-backed kitchen utensil metadata store.
final kitchenUtensilStoreProvider = Provider<KitchenUtensilStore>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    log(
      'Falling back to unavailable kitchen utensil store.',
      name: _dataProviderLogName,
    );
    return const _UnavailableKitchenUtensilStore();
  }
  return FirestoreKitchenUtensilStore(firestore: firestore);
});

/// Firebase Storage-backed kitchen utensil image store.
final kitchenUtensilImageStoreProvider = Provider<KitchenUtensilImageStore>((
  ref,
) {
  final storage = ref.watch(firebaseStorageProvider);
  if (storage == null) {
    log(
      'Falling back to unavailable kitchen utensil image store.',
      name: _dataProviderLogName,
    );
    return const _UnavailableKitchenUtensilImageStore();
  }
  return FirebaseKitchenUtensilImageStore(storage: storage);
});

class _CurrentKitchenUtensilUserSession implements InventoryUserSession {
  const _CurrentKitchenUtensilUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailableKitchenUtensilStore implements KitchenUtensilStore {
  const _UnavailableKitchenUtensilStore();

  @override
  Future<List<KitchenUtensilDocument>> readAll({
    required String userId,
  }) async {
    return const <KitchenUtensilDocument>[];
  }

  @override
  Stream<List<KitchenUtensilDocument>> watchAll({required String userId}) {
    return Stream<List<KitchenUtensilDocument>>.value(
      const <KitchenUtensilDocument>[],
    );
  }

  @override
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  }) async {
    return false;
  }

  @override
  Future<bool> delete({
    required String userId,
    required String utensilId,
  }) async {
    return false;
  }
}

class _UnavailableKitchenUtensilImageStore implements KitchenUtensilImageStore {
  const _UnavailableKitchenUtensilImageStore();

  @override
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    return null;
  }

  @override
  Future<bool> deleteImage(String path) async {
    return false;
  }

  @override
  Future<String?> downloadUrl(String path) async {
    return null;
  }
}
