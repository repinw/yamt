// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_key_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the household key of the active household.
///
/// Creates the own household when the user has none yet. Each member holds
/// the household key wrapped with their own data key. A member who started
/// fresh lost that entry: with other members left, they ask them for the key;
/// alone, the household data is wiped and a new key follows.

@ProviderFor(HouseholdKeySession)
final householdKeySessionProvider = HouseholdKeySessionProvider._();

/// Resolves the household key of the active household.
///
/// Creates the own household when the user has none yet. Each member holds
/// the household key wrapped with their own data key. A member who started
/// fresh lost that entry: with other members left, they ask them for the key;
/// alone, the household data is wiped and a new key follows.
final class HouseholdKeySessionProvider
    extends $AsyncNotifierProvider<HouseholdKeySession, HouseholdKeyState> {
  /// Resolves the household key of the active household.
  ///
  /// Creates the own household when the user has none yet. Each member holds
  /// the household key wrapped with their own data key. A member who started
  /// fresh lost that entry: with other members left, they ask them for the key;
  /// alone, the household data is wiped and a new key follows.
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
    r'031e7457538c8a4c5353f30d78146dddc7f77d4a';

/// Resolves the household key of the active household.
///
/// Creates the own household when the user has none yet. Each member holds
/// the household key wrapped with their own data key. A member who started
/// fresh lost that entry: with other members left, they ask them for the key;
/// alone, the household data is wiped and a new key follows.

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

/// The cipher for the active household, or `null` while the household key
/// is not ready.

@ProviderFor(householdCipher)
final householdCipherProvider = HouseholdCipherProvider._();

/// The cipher for the active household, or `null` while the household key
/// is not ready.

final class HouseholdCipherProvider
    extends
        $FunctionalProvider<
          HouseholdCipher?,
          HouseholdCipher?,
          HouseholdCipher?
        >
    with $Provider<HouseholdCipher?> {
  /// The cipher for the active household, or `null` while the household key
  /// is not ready.
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

String _$householdCipherHash() => r'437b224a4329acce1ce81474a83490a6b06103af';
