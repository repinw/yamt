// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ticker period for minute-sensitive balance UI updates.

@ProviderFor(diaryBalanceTickerDuration)
final diaryBalanceTickerDurationProvider =
    DiaryBalanceTickerDurationProvider._();

/// Ticker period for minute-sensitive balance UI updates.

final class DiaryBalanceTickerDurationProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// Ticker period for minute-sensitive balance UI updates.
  DiaryBalanceTickerDurationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBalanceTickerDurationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceTickerDurationHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return diaryBalanceTickerDuration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$diaryBalanceTickerDurationHash() =>
    r'878cc7c98c368fcde1eab115c9da262b58a38029';

/// Optional observer for balance ticker tests.

@ProviderFor(diaryBalanceTickerObserver)
final diaryBalanceTickerObserverProvider =
    DiaryBalanceTickerObserverProvider._();

/// Optional observer for balance ticker tests.

final class DiaryBalanceTickerObserverProvider
    extends $FunctionalProvider<VoidCallback?, VoidCallback?, VoidCallback?>
    with $Provider<VoidCallback?> {
  /// Optional observer for balance ticker tests.
  DiaryBalanceTickerObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBalanceTickerObserverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceTickerObserverHash();

  @$internal
  @override
  $ProviderElement<VoidCallback?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoidCallback? create(Ref ref) {
    return diaryBalanceTickerObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoidCallback? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoidCallback?>(value),
    );
  }
}

String _$diaryBalanceTickerObserverHash() =>
    r'0683c7a062fbc4c656db625945ee8995da82bb0b';
