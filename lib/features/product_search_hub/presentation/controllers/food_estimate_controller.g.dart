// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_estimate_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Collects photos and runs the AI food estimate.

@ProviderFor(FoodEstimateController)
final foodEstimateControllerProvider = FoodEstimateControllerProvider._();

/// Collects photos and runs the AI food estimate.
final class FoodEstimateControllerProvider
    extends $NotifierProvider<FoodEstimateController, FoodEstimateState> {
  /// Collects photos and runs the AI food estimate.
  FoodEstimateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodEstimateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodEstimateControllerHash();

  @$internal
  @override
  FoodEstimateController create() => FoodEstimateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodEstimateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodEstimateState>(value),
    );
  }
}

String _$foodEstimateControllerHash() =>
    r'a11e1a1bfdd4acd72696d19b72b9f35a92e60b8a';

/// Collects photos and runs the AI food estimate.

abstract class _$FoodEstimateController extends $Notifier<FoodEstimateState> {
  FoodEstimateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FoodEstimateState, FoodEstimateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodEstimateState, FoodEstimateState>,
              FoodEstimateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
