// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_calorie_log_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preparedMealCalorieLogBridge)
final preparedMealCalorieLogBridgeProvider =
    PreparedMealCalorieLogBridgeProvider._();

final class PreparedMealCalorieLogBridgeProvider
    extends
        $FunctionalProvider<
          PreparedMealCalorieLogBridge,
          PreparedMealCalorieLogBridge,
          PreparedMealCalorieLogBridge
        >
    with $Provider<PreparedMealCalorieLogBridge> {
  PreparedMealCalorieLogBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealCalorieLogBridgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealCalorieLogBridgeHash();

  @$internal
  @override
  $ProviderElement<PreparedMealCalorieLogBridge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealCalorieLogBridge create(Ref ref) {
    return preparedMealCalorieLogBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealCalorieLogBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealCalorieLogBridge>(value),
    );
  }
}

String _$preparedMealCalorieLogBridgeHash() =>
    r'aa929d34f86f70e5cc75e732d9a63bca873a4ec0';
