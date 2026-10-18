// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The manual weight entries, and the weighings that the user adds, changes,
/// or deletes: in Health when it is ready, else as manual entries.

@ProviderFor(ManualHealthWeightEntriesController)
final manualHealthWeightEntriesControllerProvider =
    ManualHealthWeightEntriesControllerProvider._();

/// The manual weight entries, and the weighings that the user adds, changes,
/// or deletes: in Health when it is ready, else as manual entries.
final class ManualHealthWeightEntriesControllerProvider
    extends
        $AsyncNotifierProvider<
          ManualHealthWeightEntriesController,
          List<ManualHealthWeightEntry>
        > {
  /// The manual weight entries, and the weighings that the user adds, changes,
  /// or deletes: in Health when it is ready, else as manual entries.
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
    r'271009802d22279452cf0a6384bf4d97659894d6';

/// The manual weight entries, and the weighings that the user adds, changes,
/// or deletes: in Health when it is ready, else as manual entries.

abstract class _$ManualHealthWeightEntriesController
    extends $AsyncNotifier<List<ManualHealthWeightEntry>> {
  FutureOr<List<ManualHealthWeightEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
