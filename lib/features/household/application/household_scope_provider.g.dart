// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_scope_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The household that the profile names as active, or `null` while signed
/// out or before the own household exists.

@ProviderFor(householdDataOwnerUserId)
final householdDataOwnerUserIdProvider = HouseholdDataOwnerUserIdProvider._();

/// The household that the profile names as active, or `null` while signed
/// out or before the own household exists.

final class HouseholdDataOwnerUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The household that the profile names as active, or `null` while signed
  /// out or before the own household exists.
  HouseholdDataOwnerUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdDataOwnerUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdDataOwnerUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return householdDataOwnerUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$householdDataOwnerUserIdHash() =>
    r'3583a19dd0ca02faf370a81da0d544eea0cd546f';

/// The own household of the signed-in user, or `null` while signed out or
/// before it exists.

@ProviderFor(ownHouseholdId)
final ownHouseholdIdProvider = OwnHouseholdIdProvider._();

/// The own household of the signed-in user, or `null` while signed out or
/// before it exists.

final class OwnHouseholdIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The own household of the signed-in user, or `null` while signed out or
  /// before it exists.
  OwnHouseholdIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownHouseholdIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownHouseholdIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return ownHouseholdId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$ownHouseholdIdHash() => r'd939753bd2b9535b5c0abb0e68ce21d8f53d2ea7';

/// Switches household scoped data to the own household when the active one
/// denies access, until the profile names the own household again.

@ProviderFor(HouseholdDataOwnerRecovery)
final householdDataOwnerRecoveryProvider =
    HouseholdDataOwnerRecoveryProvider._();

/// Switches household scoped data to the own household when the active one
/// denies access, until the profile names the own household again.
final class HouseholdDataOwnerRecoveryProvider
    extends
        $NotifierProvider<
          HouseholdDataOwnerRecovery,
          HouseholdDataOwnerRecoveryState?
        > {
  /// Switches household scoped data to the own household when the active one
  /// denies access, until the profile names the own household again.
  HouseholdDataOwnerRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdDataOwnerRecoveryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdDataOwnerRecoveryHash();

  @$internal
  @override
  HouseholdDataOwnerRecovery create() => HouseholdDataOwnerRecovery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdDataOwnerRecoveryState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdDataOwnerRecoveryState?>(
        value,
      ),
    );
  }
}

String _$householdDataOwnerRecoveryHash() =>
    r'84692e5670e7dbe96bb829a0816efab6b479ec2c';

/// Switches household scoped data to the own household when the active one
/// denies access, until the profile names the own household again.

abstract class _$HouseholdDataOwnerRecovery
    extends $Notifier<HouseholdDataOwnerRecoveryState?> {
  HouseholdDataOwnerRecoveryState? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              HouseholdDataOwnerRecoveryState?,
              HouseholdDataOwnerRecoveryState?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                HouseholdDataOwnerRecoveryState?,
                HouseholdDataOwnerRecoveryState?
              >,
              HouseholdDataOwnerRecoveryState?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The id of the household whose data the user sees now.

@ProviderFor(activeHouseholdId)
final activeHouseholdIdProvider = ActiveHouseholdIdProvider._();

/// The id of the household whose data the user sees now.

final class ActiveHouseholdIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The id of the household whose data the user sees now.
  ActiveHouseholdIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeHouseholdIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeHouseholdIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activeHouseholdId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeHouseholdIdHash() => r'71226b8a5d77b7d918d114c70c33c66e11117af5';
