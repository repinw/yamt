// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_connection_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps calorie settings in sync with Health connection state.

@ProviderFor(calorieHealthConnectionSync)
final calorieHealthConnectionSyncProvider =
    CalorieHealthConnectionSyncProvider._();

/// Keeps calorie settings in sync with Health connection state.

final class CalorieHealthConnectionSyncProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps calorie settings in sync with Health connection state.
  CalorieHealthConnectionSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieHealthConnectionSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieHealthConnectionSyncHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return calorieHealthConnectionSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$calorieHealthConnectionSyncHash() =>
    r'aefe8d47c1d4c40b043cd344523d6bdf18f1c1a7';
