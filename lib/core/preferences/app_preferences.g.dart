// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides app preference store singleton.

@ProviderFor(appPreferences)
final appPreferencesProvider = AppPreferencesProvider._();

/// Provides app preference store singleton.

final class AppPreferencesProvider
    extends $FunctionalProvider<AppPreferences, AppPreferences, AppPreferences>
    with $Provider<AppPreferences> {
  /// Provides app preference store singleton.
  AppPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPreferencesHash();

  @$internal
  @override
  $ProviderElement<AppPreferences> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppPreferences create(Ref ref) {
    return appPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppPreferences>(value),
    );
  }
}

String _$appPreferencesHash() => r'3eea652725d3ebbb71cb278aaf1b2a8cb8aa3a91';
