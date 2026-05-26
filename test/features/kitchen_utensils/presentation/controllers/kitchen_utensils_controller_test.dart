import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';
import 'package:yamt/features/kitchen_utensils/presentation/controllers/'
    'kitchen_utensils_controller.dart';

class _FakeKitchenUtensilRepository implements KitchenUtensilRepository {
  _FakeKitchenUtensilRepository({List<KitchenUtensil>? initialUtensils})
    : _utensils = List<KitchenUtensil>.from(
        initialUtensils ?? const <KitchenUtensil>[],
      );

  final StreamController<List<KitchenUtensil>> _controller =
      StreamController<List<KitchenUtensil>>.broadcast();
  List<KitchenUtensil> _utensils;
  bool uploadSucceeds = true;
  bool saveSucceeds = true;
  bool deleteSucceeds = true;
  final uploadedPaths = <String>[];
  final deletedImagePaths = <String>[];

  @override
  Stream<List<KitchenUtensil>> watchAll() {
    return Stream<List<KitchenUtensil>>.multi((controller) {
      controller.add(List<KitchenUtensil>.from(_utensils));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<KitchenUtensil>> readAll() async {
    return List<KitchenUtensil>.from(_utensils);
  }

  @override
  Future<bool> save(KitchenUtensil utensil) async {
    if (!saveSucceeds) {
      return false;
    }
    final index = _utensils.indexWhere((current) => current.id == utensil.id);
    if (index < 0) {
      _utensils = [..._utensils, utensil];
    } else {
      final nextUtensils = List<KitchenUtensil>.from(_utensils);
      nextUtensils[index] = utensil;
      _utensils = nextUtensils;
    }
    _controller.add(List<KitchenUtensil>.from(_utensils));
    return true;
  }

  @override
  Future<bool> delete(String utensilId) async {
    if (!deleteSucceeds) {
      return false;
    }
    _utensils = _utensils
        .where((utensil) => utensil.id != utensilId)
        .toList(growable: false);
    _controller.add(List<KitchenUtensil>.from(_utensils));
    return true;
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    if (!uploadSucceeds) {
      return null;
    }
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

  Future<void> dispose() => _controller.close();
}

ProviderContainer _buildContainer(_FakeKitchenUtensilRepository repository) {
  final container = ProviderContainer(
    overrides: [
      householdDataOwnerUserIdProvider.overrideWith((ref) => 'owner-1'),
      kitchenUtensilRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

ProviderSubscription<AsyncValue<List<KitchenUtensil>>> _keepAlive(
  ProviderContainer container,
) {
  return container.listen(
    kitchenUtensilsControllerProvider,
    (previous, next) {},
  );
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

void main() {
  test('addUtensil saves name and weight', () async {
    final repository = _FakeKitchenUtensilRepository();
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final result = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .addUtensil(name: 'Pot', weightGrams: 420);

    expect(result.isSuccess, isTrue);
    final utensils = container.read(kitchenUtensilsControllerProvider).value!;
    expect(utensils, hasLength(1));
    expect(utensils.single.name, 'Pot');
    expect(utensils.single.weightGrams, 420);
  });

  test('addUtensil rejects missing name and image', () async {
    final repository = _FakeKitchenUtensilRepository();
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final result = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .addUtensil(weightGrams: 420);

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      KitchenUtensilSaveFailureReason.invalidInput,
    );
    expect(container.read(kitchenUtensilsControllerProvider).value, isEmpty);
  });

  test('addUtensil reports upload failure', () async {
    final repository = _FakeKitchenUtensilRepository()..uploadSucceeds = false;
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final result = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .addUtensil(
          imageBytes: Uint8List.fromList(<int>[1]),
          weightGrams: 420,
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      KitchenUtensilSaveFailureReason.imageUploadFailed,
    );
  });

  test('addUtensil deletes uploaded image when metadata save fails', () async {
    final repository = _FakeKitchenUtensilRepository()..saveSucceeds = false;
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final result = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .addUtensil(
          imageBytes: Uint8List.fromList(<int>[1]),
          weightGrams: 420,
        );

    expect(result.isSuccess, isFalse);
    expect(repository.uploadedPaths, hasLength(1));
    expect(repository.deletedImagePaths, repository.uploadedPaths);
  });

  test('updateUtensil rejects removing only identity', () async {
    final repository = _FakeKitchenUtensilRepository(
      initialUtensils: [
        _utensil(name: null, imageStoragePath: 'users/owner-1/pot.jpg'),
      ],
    );
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final result = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .updateUtensil(
          utensilId: 'pot-1',
          imageChanged: true,
          weightGrams: 420,
        );

    expect(result.isSuccess, isFalse);
    expect(
      result.failureReason,
      KitchenUtensilSaveFailureReason.invalidInput,
    );
  });

  test('deleteUtensil removes metadata and schedules image cleanup', () async {
    final repository = _FakeKitchenUtensilRepository(
      initialUtensils: [
        _utensil(imageStoragePath: 'users/owner-1/pot.jpg'),
      ],
    );
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await container.read(kitchenUtensilsControllerProvider.future);
    final deleted = await container
        .read(kitchenUtensilsControllerProvider.notifier)
        .deleteUtensil('pot-1');

    expect(deleted, isTrue);
    expect(container.read(kitchenUtensilsControllerProvider).value, isEmpty);
    expect(repository.deletedImagePaths, ['users/owner-1/pot.jpg']);
  });
}
