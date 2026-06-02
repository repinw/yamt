// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_activity_cache_warmup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Warms aggregate Health activity cache for the rolling learning window.

@ProviderFor(calorieHealthActivityCacheWarmup)
final calorieHealthActivityCacheWarmupProvider =
    CalorieHealthActivityCacheWarmupProvider._();

/// Warms aggregate Health activity cache for the rolling learning window.

final class CalorieHealthActivityCacheWarmupProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Warms aggregate Health activity cache for the rolling learning window.
  CalorieHealthActivityCacheWarmupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieHealthActivityCacheWarmupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieHealthActivityCacheWarmupHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return calorieHealthActivityCacheWarmup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$calorieHealthActivityCacheWarmupHash() =>
    r'00660747aa61f2fa7e371b34cec9a39a3d864f07';
