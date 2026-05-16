// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current clock for manual weight timestamps.

@ProviderFor(manualHealthWeightNow)
final manualHealthWeightNowProvider = ManualHealthWeightNowProvider._();

/// Provides the current clock for manual weight timestamps.

final class ManualHealthWeightNowProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Provides the current clock for manual weight timestamps.
  ManualHealthWeightNowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualHealthWeightNowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualHealthWeightNowHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return manualHealthWeightNow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$manualHealthWeightNowHash() =>
    r'3b9f238bdf96bffc29537e9e73fbbf5d90fb7f1c';

/// Defines manual health weight entries controller.

@ProviderFor(ManualHealthWeightEntriesController)
final manualHealthWeightEntriesControllerProvider =
    ManualHealthWeightEntriesControllerProvider._();

/// Defines manual health weight entries controller.
final class ManualHealthWeightEntriesControllerProvider
    extends
        $AsyncNotifierProvider<
          ManualHealthWeightEntriesController,
          List<ManualHealthWeightEntry>
        > {
  /// Defines manual health weight entries controller.
  ManualHealthWeightEntriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualHealthWeightEntriesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$manualHealthWeightEntriesControllerHash();

  @$internal
  @override
  ManualHealthWeightEntriesController create() =>
      ManualHealthWeightEntriesController();
}

String _$manualHealthWeightEntriesControllerHash() =>
    r'ebe7cb279ed501ad648e6009996143ad1639a7c7';

/// Defines manual health weight entries controller.

abstract class _$ManualHealthWeightEntriesController
    extends $AsyncNotifier<List<ManualHealthWeightEntry>> {
  FutureOr<List<ManualHealthWeightEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ManualHealthWeightEntry>>,
              List<ManualHealthWeightEntry>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ManualHealthWeightEntry>>,
                List<ManualHealthWeightEntry>
              >,
              AsyncValue<List<ManualHealthWeightEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
