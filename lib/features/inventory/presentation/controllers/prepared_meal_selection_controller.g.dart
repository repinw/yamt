// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines prepared meal selection controller.

@ProviderFor(PreparedMealSelectionController)
final preparedMealSelectionControllerProvider =
    PreparedMealSelectionControllerProvider._();

/// Defines prepared meal selection controller.
final class PreparedMealSelectionControllerProvider
    extends
        $NotifierProvider<
          PreparedMealSelectionController,
          PreparedMealSelectionState
        > {
  /// Defines prepared meal selection controller.
  PreparedMealSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealSelectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealSelectionControllerHash();

  @$internal
  @override
  PreparedMealSelectionController create() => PreparedMealSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealSelectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealSelectionState>(value),
    );
  }
}

String _$preparedMealSelectionControllerHash() =>
    r'5c049b8c71b1f3d64084d4ee04a1fb8dbbdf5d9b';

/// Defines prepared meal selection controller.

abstract class _$PreparedMealSelectionController
    extends $Notifier<PreparedMealSelectionState> {
  PreparedMealSelectionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<PreparedMealSelectionState, PreparedMealSelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                PreparedMealSelectionState,
                PreparedMealSelectionState
              >,
              PreparedMealSelectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
