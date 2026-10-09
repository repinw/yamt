import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_image_store.dart';

const _dataProviderLogName = 'KitchenUtensilDataProviders';

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

class _UnavailableKitchenUtensilImageStore implements KitchenUtensilImageStore {
  const new();

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
