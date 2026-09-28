// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_scope_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household data owner user id.

@ProviderFor(householdDataOwnerUserId)
final householdDataOwnerUserIdProvider = HouseholdDataOwnerUserIdProvider._();

/// Household data owner user id.

final class HouseholdDataOwnerUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Household data owner user id.
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
    r'c9f7a0e6270d2b609d52160fda6266369681feb7';

/// Defines household data owner recovery.

@ProviderFor(HouseholdDataOwnerRecovery)
final householdDataOwnerRecoveryProvider =
    HouseholdDataOwnerRecoveryProvider._();

/// Defines household data owner recovery.
final class HouseholdDataOwnerRecoveryProvider
    extends
        $NotifierProvider<
          HouseholdDataOwnerRecovery,
          HouseholdDataOwnerRecoveryState?
        > {
  /// Defines household data owner recovery.
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

/// Defines household data owner recovery.

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

/// Household has additional members.

@ProviderFor(householdHasAdditionalMembers)
final householdHasAdditionalMembersProvider =
    HouseholdHasAdditionalMembersProvider._();

/// Household has additional members.

final class HouseholdHasAdditionalMembersProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Household has additional members.
  HouseholdHasAdditionalMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdHasAdditionalMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdHasAdditionalMembersHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return householdHasAdditionalMembers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$householdHasAdditionalMembersHash() =>
    r'9d6443224022b0bad84aff22669a639cd37d1326';
