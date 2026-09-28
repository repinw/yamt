// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_key_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the household key of the current household data owner.
///
/// Every user owns a household key for the data under their own uid, also
/// while they are a member elsewhere, so that data stays readable after they
/// leave. A member reads the host's key from the entry the member wrote when
/// joining.

@ProviderFor(HouseholdKeySession)
final householdKeySessionProvider = HouseholdKeySessionProvider._();

/// Resolves the household key of the current household data owner.
///
/// Every user owns a household key for the data under their own uid, also
/// while they are a member elsewhere, so that data stays readable after they
/// leave. A member reads the host's key from the entry the member wrote when
/// joining.
final class HouseholdKeySessionProvider
    extends $AsyncNotifierProvider<HouseholdKeySession, HouseholdKeyState> {
  /// Resolves the household key of the current household data owner.
  ///
  /// Every user owns a household key for the data under their own uid, also
  /// while they are a member elsewhere, so that data stays readable after they
  /// leave. A member reads the host's key from the entry the member wrote when
  /// joining.
  HouseholdKeySessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdKeySessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdKeySessionHash();

  @$internal
  @override
  HouseholdKeySession create() => HouseholdKeySession();
}

String _$householdKeySessionHash() =>
    r'2ee0987f99feee0147fe8eda3779d728f1add2b8';

/// Resolves the household key of the current household data owner.
///
/// Every user owns a household key for the data under their own uid, also
/// while they are a member elsewhere, so that data stays readable after they
/// leave. A member reads the host's key from the entry the member wrote when
/// joining.

abstract class _$HouseholdKeySession extends $AsyncNotifier<HouseholdKeyState> {
  FutureOr<HouseholdKeyState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HouseholdKeyState>, HouseholdKeyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HouseholdKeyState>, HouseholdKeyState>,
              AsyncValue<HouseholdKeyState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the host of the household that the user is a member of lost the
/// household key and waits for a restore code. Always `false` for a host.

@ProviderFor(householdKeyRestoreRequested)
final householdKeyRestoreRequestedProvider =
    HouseholdKeyRestoreRequestedProvider._();

/// Whether the host of the household that the user is a member of lost the
/// household key and waits for a restore code. Always `false` for a host.

final class HouseholdKeyRestoreRequestedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the host of the household that the user is a member of lost the
  /// household key and waits for a restore code. Always `false` for a host.
  HouseholdKeyRestoreRequestedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdKeyRestoreRequestedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdKeyRestoreRequestedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return householdKeyRestoreRequested(ref);
  }
}

String _$householdKeyRestoreRequestedHash() =>
    r'62a011d068800efd8fe00c1bcc64c0bc58b87f2f';

/// The cipher for the current household data, or `null` while the household
/// key is not ready.

@ProviderFor(householdCipher)
final householdCipherProvider = HouseholdCipherProvider._();

/// The cipher for the current household data, or `null` while the household
/// key is not ready.

final class HouseholdCipherProvider
    extends
        $FunctionalProvider<
          HouseholdCipher?,
          HouseholdCipher?,
          HouseholdCipher?
        >
    with $Provider<HouseholdCipher?> {
  /// The cipher for the current household data, or `null` while the household
  /// key is not ready.
  HouseholdCipherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdCipherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdCipherHash();

  @$internal
  @override
  $ProviderElement<HouseholdCipher?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HouseholdCipher? create(Ref ref) {
    return householdCipher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdCipher? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdCipher?>(value),
    );
  }
}

String _$householdCipherHash() => r'54b2a646e8446aae376a0782b1b155a3a1a6e241';
