import 'dart:typed_data';

import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

/// Repository for household-shared kitchen utensils.
abstract interface class KitchenUtensilRepository {
  /// Watches all utensils.
  Stream<List<KitchenUtensil>> watchAll();

  /// Reads all utensils once.
  Future<List<KitchenUtensil>> readAll();

  /// Saves one utensil.
  Future<bool> save(KitchenUtensil utensil);

  /// Deletes one utensil.
  Future<bool> delete(String utensilId);

  /// Uploads utensil image and returns storage path.
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  });

  /// Deletes utensil image. Missing images count as success.
  Future<bool> deleteImage(String imageStoragePath);

  /// Resolves a public download URL for stored image path.
  Future<String?> imageUrl(String imageStoragePath);
}
