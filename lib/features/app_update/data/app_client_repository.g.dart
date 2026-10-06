// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_client_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The client repository.

@ProviderFor(appClientRepository)
final appClientRepositoryProvider = AppClientRepositoryProvider._();

/// The client repository.

final class AppClientRepositoryProvider
    extends
        $FunctionalProvider<
          AppClientRepository,
          AppClientRepository,
          AppClientRepository
        >
    with $Provider<AppClientRepository> {
  /// The client repository.
  AppClientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appClientRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appClientRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppClientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppClientRepository create(Ref ref) {
    return appClientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppClientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppClientRepository>(value),
    );
  }
}

String _$appClientRepositoryHash() =>
    r'81c8b9f582c56f45a08842198123c7bdff27e531';
