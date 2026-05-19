// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_session_local_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the current persisted cookflow session snapshot.

@ProviderFor(cookingFlowSessionSnapshot)
final cookingFlowSessionSnapshotProvider =
    CookingFlowSessionSnapshotProvider._();

/// Watches the current persisted cookflow session snapshot.

final class CookingFlowSessionSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<CookingFlowSession?>,
          CookingFlowSession?,
          FutureOr<CookingFlowSession?>
        >
    with
        $FutureModifier<CookingFlowSession?>,
        $FutureProvider<CookingFlowSession?> {
  /// Watches the current persisted cookflow session snapshot.
  CookingFlowSessionSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowSessionSnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowSessionSnapshotHash();

  @$internal
  @override
  $FutureProviderElement<CookingFlowSession?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CookingFlowSession?> create(Ref ref) {
    return cookingFlowSessionSnapshot(ref);
  }
}

String _$cookingFlowSessionSnapshotHash() =>
    r'0c394477b467d89e27fe5d7643c6ec2ac73c9852';

/// Provides reactive cookflow session coordinator.

@ProviderFor(cookingFlowSessionCoordinator)
final cookingFlowSessionCoordinatorProvider =
    CookingFlowSessionCoordinatorProvider._();

/// Provides reactive cookflow session coordinator.

final class CookingFlowSessionCoordinatorProvider
    extends
        $FunctionalProvider<
          CookingFlowSessionCoordinator,
          CookingFlowSessionCoordinator,
          CookingFlowSessionCoordinator
        >
    with $Provider<CookingFlowSessionCoordinator> {
  /// Provides reactive cookflow session coordinator.
  CookingFlowSessionCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowSessionCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowSessionCoordinatorHash();

  @$internal
  @override
  $ProviderElement<CookingFlowSessionCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookingFlowSessionCoordinator create(Ref ref) {
    return cookingFlowSessionCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowSessionCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowSessionCoordinator>(
        value,
      ),
    );
  }
}

String _$cookingFlowSessionCoordinatorHash() =>
    r'40653fccfe6790de636a976d9e2e09de93936343';

/// Provides local cookflow session store.

@ProviderFor(cookingFlowSessionLocalStore)
final cookingFlowSessionLocalStoreProvider =
    CookingFlowSessionLocalStoreProvider._();

/// Provides local cookflow session store.

final class CookingFlowSessionLocalStoreProvider
    extends
        $FunctionalProvider<
          CookingFlowSessionLocalStore,
          CookingFlowSessionLocalStore,
          CookingFlowSessionLocalStore
        >
    with $Provider<CookingFlowSessionLocalStore> {
  /// Provides local cookflow session store.
  CookingFlowSessionLocalStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowSessionLocalStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowSessionLocalStoreHash();

  @$internal
  @override
  $ProviderElement<CookingFlowSessionLocalStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookingFlowSessionLocalStore create(Ref ref) {
    return cookingFlowSessionLocalStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowSessionLocalStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowSessionLocalStore>(value),
    );
  }
}

String _$cookingFlowSessionLocalStoreHash() =>
    r'1cdd42dcde852606d5543ac014830e0a1f674625';
