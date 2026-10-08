// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_wake_lock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's screen wake lock. Kept alive, so all pages share one count.

@ProviderFor(screenWakeLock)
final screenWakeLockProvider = ScreenWakeLockProvider._();

/// The app's screen wake lock. Kept alive, so all pages share one count.

final class ScreenWakeLockProvider
    extends $FunctionalProvider<ScreenWakeLock, ScreenWakeLock, ScreenWakeLock>
    with $Provider<ScreenWakeLock> {
  /// The app's screen wake lock. Kept alive, so all pages share one count.
  ScreenWakeLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenWakeLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenWakeLockHash();

  @$internal
  @override
  $ProviderElement<ScreenWakeLock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScreenWakeLock create(Ref ref) {
    return screenWakeLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenWakeLock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenWakeLock>(value),
    );
  }
}

String _$screenWakeLockHash() => r'83196695a32344636e1eb84059b499f9eb86c5d9';
