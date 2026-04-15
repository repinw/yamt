// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_entries_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ManualHealthWeightEntriesController)
final manualHealthWeightEntriesControllerProvider =
    ManualHealthWeightEntriesControllerProvider._();

final class ManualHealthWeightEntriesControllerProvider
    extends
        $AsyncNotifierProvider<
          ManualHealthWeightEntriesController,
          List<ManualHealthWeightEntry>
        > {
  ManualHealthWeightEntriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualHealthWeightEntriesControllerProvider',
        isAutoDispose: false,
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
    r'56f07fa22847c75a6bbaa7db6acbaabc5d6f5b80';

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
