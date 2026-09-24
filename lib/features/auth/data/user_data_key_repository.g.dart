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
    r'93a1576c54711d53704a0c54eef9822889e7eb44';
