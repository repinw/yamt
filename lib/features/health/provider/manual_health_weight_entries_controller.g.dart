// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'8fca1d7e3c72de4f81844febecf8de3c88b5c0b2';

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
