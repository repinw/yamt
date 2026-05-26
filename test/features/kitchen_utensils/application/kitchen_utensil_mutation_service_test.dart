import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/application/'
    'kitchen_utensil_mutation_service.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';

class _FakeKitchenUtensilRepository implements KitchenUtensilRepository {
  bool saveSucceeds = true;
  bool deleteSucceeds = true;
  final savedUtensils = <KitchenUtensil>[];
  final deletedUtensilIds = <String>[];
  final uploadedPaths = <String>[];
  final deletedImagePaths = <String>[];

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
    savedUtensils.add(utensil);
    return saveSucceeds;
  }

  @override
  Future<bool> delete(String utensilId) async {
    deletedUtensilIds.add(utensilId);
    return deleteSucceeds;
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    final path =
        'users/owner-1/kitchen_utensils/$utensilId/images/$imageId.jpg';
    uploadedPaths.add(path);
    return path;
  }

  @override
  Future<bool> deleteImage(String imageStoragePath) async {
    deletedImagePaths.add(imageStoragePath);
    return true;
  }

  @override
  Future<String?> imageUrl(String imageStoragePath) async {
    return 'https://example.test/$imageStoragePath';
  }
}

KitchenUtensil _utensil({
  String id = 'pot-1',
  String? name = 'Pot',
  String? imageStoragePath,
  int weightGrams = 420,
}) {
  return KitchenUtensil(
    id: id,
    name: name,
    imageStoragePath: imageStoragePath,
    weightGrams: weightGrams,
    createdAt: DateTime.parse('2026-04-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-04-01T10:00:00Z'),
  );
}

KitchenUtensilMutationService _service({
  required _FakeKitchenUtensilRepository repository,
  required List<String> ids,
}) {
  return KitchenUtensilMutationService(
    repository: repository,
    createId: () => ids.removeAt(0),
  );
}

void main() {
  test('addUtensil trims name and writes optimistic state', () async {
    final repository = _FakeKitchenUtensilRepository();
    final writtenLists = <List<KitchenUtensil>>[];
    final service = _service(repository: repository, ids: ['pot-1']);

    final result = await service.addUtensil(
      previousUtensils: const <KitchenUtensil>[],
      canWrite: () => true,
      writeUtensils: writtenLists.add,
      name: ' Pot ',
      weightGrams: 420,
    );

    expect(result.isSuccess, isTrue);
    expect(result.utensilId, 'pot-1');
    expect(repository.savedUtensils.single.name, 'Pot');
    expect(writtenLists.single.single.id, 'pot-1');
  });

  test('addUtensil deletes uploaded image when metadata save fails', () async {
    final repository = _FakeKitchenUtensilRepository()..saveSucceeds = false;
    final service = _service(repository: repository, ids: ['pot-1', 'image-1']);

    final result = await service.addUtensil(
      previousUtensils: const <KitchenUtensil>[],
      canWrite: () => true,
      writeUtensils: (_) {},
      imageBytes: Uint8List.fromList(<int>[1]),
      weightGrams: 420,
    );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, KitchenUtensilSaveFailureReason.saveFailed);
    expect(repository.deletedImagePaths, repository.uploadedPaths);
  });

  test(
    'updateUtensil replaces image and deletes old image after save',
    () async {
      final repository = _FakeKitchenUtensilRepository();
      final service = _service(repository: repository, ids: ['image-new']);
      final previous = [
        _utensil(
          imageStoragePath: 'users/owner-1/kitchen_utensils/pot-1/old.jpg',
        ),
      ];

      final result = await service.updateUtensil(
        previousUtensils: previous,
        canWrite: () => true,
        writeUtensils: (_) {},
        utensilId: 'pot-1',
        imageChanged: true,
        imageBytes: Uint8List.fromList(<int>[1]),
        weightGrams: 430,
        name: 'Pot',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.savedUtensils.single.weightGrams, 430);
      expect(
        repository.savedUtensils.single.imageStoragePath,
        'users/owner-1/kitchen_utensils/pot-1/images/image-new.jpg',
      );
      expect(
        repository.deletedImagePaths,
        ['users/owner-1/kitchen_utensils/pot-1/old.jpg'],
      );
    },
  );

  test('deleteUtensil rolls back optimistic state when delete fails', () async {
    final repository = _FakeKitchenUtensilRepository()..deleteSucceeds = false;
    final writtenLists = <List<KitchenUtensil>>[];
    final service = _service(repository: repository, ids: <String>[]);
    final previous = [_utensil()];

    final deleted = await service.deleteUtensil(
      previousUtensils: previous,
      canWrite: () => true,
      writeUtensils: writtenLists.add,
      utensilId: 'pot-1',
    );

    expect(deleted, isFalse);
    expect(writtenLists.first, isEmpty);
    expect(writtenLists.last, previous);
  });
}
