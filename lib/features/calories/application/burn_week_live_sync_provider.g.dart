// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_week_live_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How often Burn Week live sync should re-check the current day.

@ProviderFor(burnWeekLiveSyncTickerPeriod)
final burnWeekLiveSyncTickerPeriodProvider =
    BurnWeekLiveSyncTickerPeriodProvider._();

/// How often Burn Week live sync should re-check the current day.

final class BurnWeekLiveSyncTickerPeriodProvider
    extends $FunctionalProvider<Duration?, Duration?, Duration?>
    with $Provider<Duration?> {
  /// How often Burn Week live sync should re-check the current day.
  BurnWeekLiveSyncTickerPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnWeekLiveSyncTickerPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnWeekLiveSyncTickerPeriodHash();

  @$internal
  @override
  $ProviderElement<Duration?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration? create(Ref ref) {
    return burnWeekLiveSyncTickerPeriod(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration?>(value),
    );
  }
}

String _$burnWeekLiveSyncTickerPeriodHash() =>
    r'd97d27e1e4e02e2c694b8fd5f9ccb3990a124e44';

/// Keeps Burn Week sync active outside the widget tree.

@ProviderFor(burnWeekLiveSync)
final burnWeekLiveSyncProvider = BurnWeekLiveSyncProvider._();

/// Keeps Burn Week sync active outside the widget tree.

final class BurnWeekLiveSyncProvider
    extends $FunctionalProvider<Object?, Object?, Object?>
    with $Provider<Object?> {
  /// Keeps Burn Week sync active outside the widget tree.
  BurnWeekLiveSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnWeekLiveSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnWeekLiveSyncHash();

  @$internal
  @override
  $ProviderElement<Object?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Object? create(Ref ref) {
    return burnWeekLiveSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Object? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Object?>(value),
    );
  }
}

String _$burnWeekLiveSyncHash() => r'0273685e6367847b2ab0b20a0b882dc9db2888b1';
