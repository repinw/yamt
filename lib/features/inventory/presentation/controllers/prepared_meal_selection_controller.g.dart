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
    r'2cf0a8d584c9f7a54208d97e25f4e1f9d0193546';

/// Defines prepared meal selection controller.

abstract class _$PreparedMealSelectionController
    extends $Notifier<PreparedMealSelectionState> {
  PreparedMealSelectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
