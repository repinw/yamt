// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_household_invite.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// An invite link that opened the app and waits for the join form.

@ProviderFor(PendingHouseholdInvite)
final pendingHouseholdInviteProvider = PendingHouseholdInviteProvider._();

/// An invite link that opened the app and waits for the join form.
final class PendingHouseholdInviteProvider
    extends $NotifierProvider<PendingHouseholdInvite, HouseholdInvite?> {
  /// An invite link that opened the app and waits for the join form.
  PendingHouseholdInviteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingHouseholdInviteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingHouseholdInviteHash();

  @$internal
  @override
  PendingHouseholdInvite create() => PendingHouseholdInvite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdInvite? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdInvite?>(value),
    );
  }
}

String _$pendingHouseholdInviteHash() =>
    r'8b810722bd12f5c3c3ef2c353b11e229b557b8ac';

/// An invite link that opened the app and waits for the join form.

abstract class _$PendingHouseholdInvite extends $Notifier<HouseholdInvite?> {
  HouseholdInvite? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HouseholdInvite?, HouseholdInvite?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HouseholdInvite?, HouseholdInvite?>,
              HouseholdInvite?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
