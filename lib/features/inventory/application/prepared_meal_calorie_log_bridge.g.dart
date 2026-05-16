// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_calorie_log_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The prepared meal calorie log bridge provider.

@ProviderFor(preparedMealCalorieLogBridge)
final preparedMealCalorieLogBridgeProvider =
    PreparedMealCalorieLogBridgeProvider._();

/// The prepared meal calorie log bridge provider.

final class PreparedMealCalorieLogBridgeProvider
    extends
        $FunctionalProvider<
          PreparedMealCalorieLogBridge,
          PreparedMealCalorieLogBridge,
          PreparedMealCalorieLogBridge
        >
    with $Provider<PreparedMealCalorieLogBridge> {
  /// The prepared meal calorie log bridge provider.
  PreparedMealCalorieLogBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealCalorieLogBridgeProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          preparedMealCalorieEntryCommitStoreProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PreparedMealCalorieLogBridgeProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 =
      preparedMealCalorieEntryCommitStoreProvider;

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
    r'7ed0ebaa031ac7d4236ca52f3b9e0556cd865234';
