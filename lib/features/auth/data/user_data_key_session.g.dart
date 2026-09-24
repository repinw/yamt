// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_key_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the data key of the signed-in user.
///
/// A guest key lives only on the device. A real account also gets a key
/// backup in Firestore that only the recovery key opens. The recovery key is
/// also backed up with the platform (Google Block Store, iCloud Keychain), so
/// a new device usually restores the data key without asking.

@ProviderFor(UserDataKeySession)
final userDataKeySessionProvider = UserDataKeySessionProvider._();

/// Resolves the data key of the signed-in user.
///
/// A guest key lives only on the device. A real account also gets a key
/// backup in Firestore that only the recovery key opens. The recovery key is
/// also backed up with the platform (Google Block Store, iCloud Keychain), so
/// a new device usually restores the data key without asking.
final class UserDataKeySessionProvider
    extends $AsyncNotifierProvider<UserDataKeySession, UserDataKeyState> {
  /// Resolves the data key of the signed-in user.
  ///
  /// A guest key lives only on the device. A real account also gets a key
  /// backup in Firestore that only the recovery key opens. The recovery key is
  /// also backed up with the platform (Google Block Store, iCloud Keychain), so
  /// a new device usually restores the data key without asking.
  UserDataKeySessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataKeySessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataKeySessionHash();

  @$internal
  @override
  UserDataKeySession create() => UserDataKeySession();
}

String _$userDataKeySessionHash() =>
    r'a7200685cc33372b0070fc3093f883620341f7f2';

/// Resolves the data key of the signed-in user.
///
/// A guest key lives only on the device. A real account also gets a key
/// backup in Firestore that only the recovery key opens. The recovery key is
/// also backed up with the platform (Google Block Store, iCloud Keychain), so
/// a new device usually restores the data key without asking.

abstract class _$UserDataKeySession extends $AsyncNotifier<UserDataKeyState> {
  FutureOr<UserDataKeyState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UserDataKeyState>, UserDataKeyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserDataKeyState>, UserDataKeyState>,
              AsyncValue<UserDataKeyState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The cipher for the private data of the signed-in user, or `null` while
/// the data key is not ready.
///
/// It carries the uid, so a repository never combines the key of one user with
/// the documents of another while the session switches users.

@ProviderFor(userDataCipher)
final userDataCipherProvider = UserDataCipherProvider._();

/// The cipher for the private data of the signed-in user, or `null` while
/// the data key is not ready.
///
/// It carries the uid, so a repository never combines the key of one user with
/// the documents of another while the session switches users.

final class UserDataCipherProvider
    extends
        $FunctionalProvider<UserDataCipher?, UserDataCipher?, UserDataCipher?>
    with $Provider<UserDataCipher?> {
  /// The cipher for the private data of the signed-in user, or `null` while
  /// the data key is not ready.
  ///
  /// It carries the uid, so a repository never combines the key of one user with
  /// the documents of another while the session switches users.
  UserDataCipherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataCipherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataCipherHash();

  @$internal
  @override
  $ProviderElement<UserDataCipher?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserDataCipher? create(Ref ref) {
    return userDataCipher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserDataCipher? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserDataCipher?>(value),
    );
  }
}

String _$userDataCipherHash() => r'41dee7ee8cfd919754bde87b367a33b6bc4a28ea';
