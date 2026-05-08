import 'dart:typed_data';

import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

/// Normalizes an optional kitchen utensil name.
String? normalizeKitchenUtensilName(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Whether a kitchen utensil draft has enough identity.
bool hasKitchenUtensilIdentity({
  required String? name,
  required Uint8List? imageBytes,
  required String? imageStoragePath,
}) {
  final hasName = (name ?? '').trim().isNotEmpty;
  final hasImageBytes = imageBytes != null;
  final hasImagePath = (imageStoragePath ?? '').trim().isNotEmpty;
  return hasName || hasImageBytes || hasImagePath;
}

/// Whether kitchen utensil input can be saved.
bool isValidKitchenUtensilInput({
  required String? name,
  required Uint8List? imageBytes,
  required String? imageStoragePath,
  required int weightGrams,
}) {
  if (weightGrams <= 0) {
    return false;
  }
  return hasKitchenUtensilIdentity(
    name: name,
    imageBytes: imageBytes,
    imageStoragePath: imageStoragePath,
  );
}

/// Sorts utensils by updated date, then created date.
List<KitchenUtensil> sortKitchenUtensils(List<KitchenUtensil> utensils) {
  final sortedUtensils = List<KitchenUtensil>.from(utensils)
    ..sort((left, right) {
      final byUpdate = right.updatedAt.compareTo(left.updatedAt);
      if (byUpdate != 0) {
        return byUpdate;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
  return List<KitchenUtensil>.unmodifiable(sortedUtensils);
}
