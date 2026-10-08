import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/application/'
    'household_scoped_list_feed.dart';
import 'package:yamt/features/kitchen_utensils/application/'
    'kitchen_utensil_mutation_service.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil_rules.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';

part 'kitchen_utensils_controller.g.dart';

const _saveFailed = KitchenUtensilSaveResult.failure(
  KitchenUtensilSaveFailureReason.saveFailed,
);

const _kitchenUtensilsControllerLogName = 'KitchenUtensilsController';

/// Kitchen utensils controller.
@riverpod
class KitchenUtensilsController extends _$KitchenUtensilsController {
  final _mutationQueue = SerializedMutationQueue();
  late final _feed = HouseholdScopedListFeed<KitchenUtensil>(
    ref: () => ref,
    watch: () => ref
        .read(kitchenUtensilRepositoryProvider)
        .watchAll()
        .map(sortKitchenUtensils),
    setState: (next) => state = next,
    logName: _kitchenUtensilsControllerLogName,
    recoveryMessage:
        'Rebuilding kitchen utensil stream after household access changed.',
  );

  @override
  FutureOr<List<KitchenUtensil>> build() {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(kitchenUtensilRepositoryProvider)
      ..onDispose(() {
        unawaited(_feed.close());
      })
      ..watch(activeHouseholdIdProvider);
    return _feed.start();
  }

  /// Refreshes utensils.
  Future<void> refresh() => _feed.refresh();

  /// Adds a utensil.
  Future<KitchenUtensilSaveResult> addUtensil({
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) {
    return _runMutation(
      name: 'add',
      fallbackValue: _saveFailed,
      operation: (service, previousUtensils) => service.addUtensil(
        previousUtensils: previousUtensils,
        canWrite: () => ref.mounted,
        writeUtensils: _writeUtensils,
        name: name,
        imageBytes: imageBytes,
        weightGrams: weightGrams,
      ),
    );
  }

  /// Updates a utensil. A replaced image stays in storage for an undo; delete
  /// it with [discardImage] afterwards.
  Future<KitchenUtensilSaveResult> updateUtensil({
    required String utensilId,
    required bool imageChanged,
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) {
    return _runMutation(
      name: 'update',
      fallbackValue: _saveFailed,
      operation: (service, previousUtensils) => service.updateUtensil(
        previousUtensils: previousUtensils,
        canWrite: () => ref.mounted,
        writeUtensils: _writeUtensils,
        utensilId: utensilId,
        name: name,
        imageBytes: imageBytes,
        imageChanged: imageChanged,
        weightGrams: weightGrams,
      ),
    );
  }

  /// Deletes a utensil and returns it, or null on failure. Its image stays in
  /// storage for an undo; delete it with [discardImage] afterwards.
  Future<KitchenUtensil?> deleteUtensil(String utensilId) {
    return _runMutation<KitchenUtensil?>(
      name: 'delete',
      fallbackValue: null,
      operation: (service, previousUtensils) => service.deleteUtensil(
        previousUtensils: previousUtensils,
        canWrite: () => ref.mounted,
        writeUtensils: _writeUtensils,
        utensilId: utensilId,
      ),
    );
  }

  /// Saves [utensil] back as it was before an update or delete, and deletes
  /// the image of the version it replaces.
  Future<bool> restoreUtensil(KitchenUtensil utensil) {
    return _runMutation(
      name: 'restore',
      fallbackValue: false,
      operation: (service, previousUtensils) async {
        final (:restored, :replacedImagePath) = await service.restoreUtensil(
          previousUtensils: previousUtensils,
          canWrite: () => ref.mounted,
          writeUtensils: _writeUtensils,
          utensil: utensil,
        );
        if (replacedImagePath != null) {
          unawaited(service.deleteImage(replacedImagePath));
        }
        return restored;
      },
    );
  }

  /// Deletes an image that an update or delete left in storage.
  Future<bool> discardImage(String imageStoragePath) {
    return ref
        .read(kitchenUtensilMutationServiceProvider)
        .deleteImage(imageStoragePath);
  }

  Future<T> _runMutation<T>({
    required String name,
    required T fallbackValue,
    required Future<T> Function(
      KitchenUtensilMutationService service,
      List<KitchenUtensil> previousUtensils,
    )
    operation,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<T>(
          operation: () async {
            final repository = ref.read(kitchenUtensilRepositoryProvider);
            final service = ref.read(kitchenUtensilMutationServiceProvider);
            final previousUtensils = await _currentUtensils(repository);
            if (!ref.mounted) {
              return fallbackValue;
            }
            return await operation(service, previousUtensils);
          },
          fallbackValue: fallbackValue,
          onError: (error, stackTrace) {
            log(
              'Unexpected kitchen utensil $name error.',
              name: _kitchenUtensilsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  Future<List<KitchenUtensil>> _currentUtensils(
    KitchenUtensilRepository repository,
  ) async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    final utensils = await repository.readAll();
    return sortKitchenUtensils(utensils);
  }

  void _writeUtensils(List<KitchenUtensil> utensils) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(utensils);
  }
}
