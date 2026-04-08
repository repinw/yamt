// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_scope_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(householdDataOwnerUserId)
final householdDataOwnerUserIdProvider = HouseholdDataOwnerUserIdProvider._();

final class HouseholdDataOwnerUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
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

@ProviderFor(HouseholdDataOwnerRecovery)
final householdDataOwnerRecoveryProvider =
    HouseholdDataOwnerRecoveryProvider._();

final class HouseholdDataOwnerRecoveryProvider
    extends
        $NotifierProvider<
          HouseholdDataOwnerRecovery,
          HouseholdDataOwnerRecoveryState?
        > {
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

abstract class _$HouseholdDataOwnerRecovery
    extends $Notifier<HouseholdDataOwnerRecoveryState?> {
  HouseholdDataOwnerRecoveryState? build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

@ProviderFor(effectiveHouseholdDataOwnerUserId)
final effectiveHouseholdDataOwnerUserIdProvider =
    EffectiveHouseholdDataOwnerUserIdProvider._();

final class EffectiveHouseholdDataOwnerUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  EffectiveHouseholdDataOwnerUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveHouseholdDataOwnerUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$effectiveHouseholdDataOwnerUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return effectiveHouseholdDataOwnerUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$effectiveHouseholdDataOwnerUserIdHash() =>
    r'abb1ed887bdc6e85b69b06c90674e86e1e25447f';

@ProviderFor(householdHasAdditionalMembers)
final householdHasAdditionalMembersProvider =
    HouseholdHasAdditionalMembersProvider._();

final class HouseholdHasAdditionalMembersProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
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
