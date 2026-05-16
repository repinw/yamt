// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_connection_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie-aware Health Connect actions.

@ProviderFor(calorieHealthConnectionActions)
final calorieHealthConnectionActionsProvider =
    CalorieHealthConnectionActionsProvider._();

/// Calorie-aware Health Connect actions.

final class CalorieHealthConnectionActionsProvider
    extends
        $FunctionalProvider<
          CalorieHealthConnectionActions,
          CalorieHealthConnectionActions,
          CalorieHealthConnectionActions
        >
    with $Provider<CalorieHealthConnectionActions> {
  /// Calorie-aware Health Connect actions.
  CalorieHealthConnectionActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieHealthConnectionActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieHealthConnectionActionsHash();

  @$internal
  @override
  $ProviderElement<CalorieHealthConnectionActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieHealthConnectionActions create(Ref ref) {
    return calorieHealthConnectionActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieHealthConnectionActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieHealthConnectionActions>(
        value,
      ),
    );
  }
}

String _$calorieHealthConnectionActionsHash() =>
    r'c1032eb5defcddd3ec96898ab43ac24767d7386a';
