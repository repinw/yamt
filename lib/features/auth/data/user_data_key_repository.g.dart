// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_key_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User data key repository, or `null` while Firestore is unavailable.

@ProviderFor(userDataKeyRepository)
final userDataKeyRepositoryProvider = UserDataKeyRepositoryProvider._();

/// User data key repository, or `null` while Firestore is unavailable.

final class UserDataKeyRepositoryProvider
    extends
        $FunctionalProvider<
          UserDataKeyRepository?,
          UserDataKeyRepository?,
          UserDataKeyRepository?
        >
    with $Provider<UserDataKeyRepository?> {
  /// User data key repository, or `null` while Firestore is unavailable.
  UserDataKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataKeyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserDataKeyRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserDataKeyRepository? create(Ref ref) {
    return userDataKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserDataKeyRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserDataKeyRepository?>(value),
    );
  }
}

String _$userDataKeyRepositoryHash() =>
    r'55a35ef4e6452e7b50b59cc6b26e96e83b35fbcf';
