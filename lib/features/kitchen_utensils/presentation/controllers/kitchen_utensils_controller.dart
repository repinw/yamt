import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
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

const _kitchenUtensilsControllerLogName = 'KitchenUtensilsController';

/// Kitchen utensils controller.
@riverpod
class KitchenUtensilsController extends _$KitchenUtensilsController {
  // Subscription is cancelled by _disposeSubscription.
  // ignore: cancel_subscriptions
  StreamSubscription<List<KitchenUtensil>>? _utensilsSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<KitchenUtensil>> build() {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(kitchenUtensilRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeSubscription());
      });
    _currentDataOwnerUserId = ref.watch(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    return _restartSubscription();
  }

  /// Refreshes utensils.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// Adds a utensil.
  Future<KitchenUtensilSaveResult> addUtensil({
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<KitchenUtensilSaveResult>(
          operation: () async {
            final repository = ref.read(kitchenUtensilRepositoryProvider);
            final service = ref.read(kitchenUtensilMutationServiceProvider);
            final previousUtensils = await _currentUtensils(repository);
            if (!ref.mounted) {
              return const KitchenUtensilSaveResult.failure(
                KitchenUtensilSaveFailureReason.saveFailed,
              );
            }
            return service.addUtensil(
              previousUtensils: previousUtensils,
              canWrite: () => ref.mounted,
              writeUtensils: _writeUtensils,
              name: name,
              imageBytes: imageBytes,
              weightGrams: weightGrams,
            );
          },
          fallbackValue: const KitchenUtensilSaveResult.failure(
            KitchenUtensilSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected kitchen utensil add error.',
              name: _kitchenUtensilsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  /// Updates a utensil.
  Future<KitchenUtensilSaveResult> updateUtensil({
    required String utensilId,
    required bool imageChanged,
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<KitchenUtensilSaveResult>(
          operation: () async {
            final repository = ref.read(kitchenUtensilRepositoryProvider);
            final service = ref.read(kitchenUtensilMutationServiceProvider);
            final previousUtensils = await _currentUtensils(repository);
            if (!ref.mounted) {
              return const KitchenUtensilSaveResult.failure(
                KitchenUtensilSaveFailureReason.saveFailed,
              );
            }
            return service.updateUtensil(
              previousUtensils: previousUtensils,
              canWrite: () => ref.mounted,
              writeUtensils: _writeUtensils,
              utensilId: utensilId,
              name: name,
              imageBytes: imageBytes,
              imageChanged: imageChanged,
              weightGrams: weightGrams,
            );
          },
          fallbackValue: const KitchenUtensilSaveResult.failure(
            KitchenUtensilSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected kitchen utensil update error.',
              name: _kitchenUtensilsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  /// Deletes a utensil.
  Future<bool> deleteUtensil(String utensilId) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<bool>(
          operation: () async {
            final repository = ref.read(kitchenUtensilRepositoryProvider);
            final service = ref.read(kitchenUtensilMutationServiceProvider);
            final previousUtensils = await _currentUtensils(repository);
            if (!ref.mounted) {
              return false;
            }
            return service.deleteUtensil(
              previousUtensils: previousUtensils,
              canWrite: () => ref.mounted,
              writeUtensils: _writeUtensils,
              utensilId: utensilId,
            );
          },
          fallbackValue: false,
          onError: (error, stackTrace) {
            log(
              'Unexpected kitchen utensil delete error.',
              name: _kitchenUtensilsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  Future<List<KitchenUtensil>> _restartSubscription() async {
    final initialUtensils = Completer<List<KitchenUtensil>>();
    _currentDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    final repository = ref.read(kitchenUtensilRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeSubscription();

    _utensilsSubscription = repository.watchAll().listen(
      (utensils) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        final sortedUtensils = sortKitchenUtensils(utensils);
        if (!initialUtensils.isCompleted) {
          initialUtensils.complete(sortedUtensils);
          return;
        }
        _onRealtimeUtensils(sortedUtensils);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialUtensils.isCompleted) {
          if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
            initialUtensils.complete(const <KitchenUtensil>[]);
            unawaited(_recoverFromRevokedHouseholdAccess(showLoading: false));
            return;
          }
          initialUtensils.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialUtensils.future;
  }

  Future<void> _disposeSubscription() async {
    final currentSubscription = _utensilsSubscription;
    _utensilsSubscription = null;
    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }
  }

  void _onRealtimeUtensils(List<KitchenUtensil> utensils) {
    _writeUtensils(utensils);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
      unawaited(_recoverFromRevokedHouseholdAccess());
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    return shouldRecoverControllerHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverControllerHouseholdAccess<KitchenUtensil>(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartHouseholdScopedSubscription: _restartSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      householdAccessRecoveryLogName: _kitchenUtensilsControllerLogName,
      householdAccessRecoveryMessage:
          'Rebuilding kitchen utensil stream after household access changed.',
      showLoading: showLoading,
    );
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
