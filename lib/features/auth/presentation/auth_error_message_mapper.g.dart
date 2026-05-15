// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_error_message_mapper.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth error message mapper.

@ProviderFor(authErrorMessageMapper)
final authErrorMessageMapperProvider = AuthErrorMessageMapperProvider._();

/// Auth error message mapper.

final class AuthErrorMessageMapperProvider
    extends
        $FunctionalProvider<
          AuthErrorMessageMapper,
          AuthErrorMessageMapper,
          AuthErrorMessageMapper
        >
    with $Provider<AuthErrorMessageMapper> {
  /// Auth error message mapper.
  AuthErrorMessageMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authErrorMessageMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authErrorMessageMapperHash();

  @$internal
  @override
  $ProviderElement<AuthErrorMessageMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthErrorMessageMapper create(Ref ref) {
    return authErrorMessageMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthErrorMessageMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthErrorMessageMapper>(value),
    );
  }
}

String _$authErrorMessageMapperHash() =>
    r'4a0e02be684a83b674ad13b9d8fd4e3d7ae9f5d9';
