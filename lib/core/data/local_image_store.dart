import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'local_image_store_factory.dart';

part 'local_image_store.g.dart';

enum LocalImageEntityType {
  preparedMeal('prepared_meals'),
  preparedMealTemplate('prepared_meal_templates'),
  calorieEntry('calorie_entries');

  const LocalImageEntityType(this.storageFolder);

  final String storageFolder;
}

class LocalImageRef {
  const LocalImageRef({required this.entityType, required this.entityId});

  const LocalImageRef.preparedMeal(String entityId)
    : this(entityType: LocalImageEntityType.preparedMeal, entityId: entityId);

  const LocalImageRef.preparedMealTemplate(String entityId)
    : this(
        entityType: LocalImageEntityType.preparedMealTemplate,
        entityId: entityId,
      );

  const LocalImageRef.calorieEntry(String entityId)
    : this(entityType: LocalImageEntityType.calorieEntry, entityId: entityId);

  final LocalImageEntityType entityType;
  final String entityId;

  String get storageKey => '${entityType.storageFolder}/$entityId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalImageRef &&
            other.entityType == entityType &&
            other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

abstract interface class LocalImageStore {
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  });

  Future<Uint8List?> readBytes(LocalImageRef imageRef);

  Future<void> deleteImage(LocalImageRef imageRef);

  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  });
}

@riverpod
LocalImageStore localImageStore(Ref ref) {
  return createLocalImageStore();
}

@riverpod
Future<Uint8List?> localImageBytes(Ref ref, LocalImageRef imageRef) {
  return ref.watch(localImageStoreProvider).readBytes(imageRef);
}
