// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_config_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The version config repository.

@ProviderFor(appVersionConfigRepository)
final appVersionConfigRepositoryProvider =
    AppVersionConfigRepositoryProvider._();

/// The version config repository.

final class AppVersionConfigRepositoryProvider
    extends
        $FunctionalProvider<
          AppVersionConfigRepository,
          AppVersionConfigRepository,
          AppVersionConfigRepository
        >
    with $Provider<AppVersionConfigRepository> {
  /// The version config repository.
  AppVersionConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppVersionConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppVersionConfigRepository create(Ref ref) {
    return appVersionConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppVersionConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppVersionConfigRepository>(value),
    );
  }
}

String _$appVersionConfigRepositoryHash() =>
    r'a03c0b98ba575e10890222214b97a3e6fe11642e';

/// Whether this app may open and whether a newer version exists.
///
/// A failed check counts as up to date, like a missing config: a lost
/// connection or a broken config must not lock anyone out. After an error
/// event the status follows the next config again.

@ProviderFor(appUpdateStatus)
final appUpdateStatusProvider = AppUpdateStatusProvider._();

/// Whether this app may open and whether a newer version exists.
///
/// A failed check counts as up to date, like a missing config: a lost
/// connection or a broken config must not lock anyone out. After an error
/// event the status follows the next config again.

final class AppUpdateStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppUpdateStatus>,
          AppUpdateStatus,
          Stream<AppUpdateStatus>
        >
    with $FutureModifier<AppUpdateStatus>, $StreamProvider<AppUpdateStatus> {
  /// Whether this app may open and whether a newer version exists.
  ///
  /// A failed check counts as up to date, like a missing config: a lost
  /// connection or a broken config must not lock anyone out. After an error
  /// event the status follows the next config again.
  AppUpdateStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateStatusHash();

  @$internal
  @override
  $StreamProviderElement<AppUpdateStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppUpdateStatus> create(Ref ref) {
    return appUpdateStatus(ref);
  }
}

String _$appUpdateStatusHash() => r'8110820a78c1237d9828b48bd25b22997ba259fe';
