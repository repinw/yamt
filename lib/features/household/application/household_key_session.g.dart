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
    r'9fff63572782fe2789e6f3b3a90639ddb9f62772';

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
