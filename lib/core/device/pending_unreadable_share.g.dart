// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_unreadable_share.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether another app shared something with yamt that we could not read and
/// no page told the user yet.

@ProviderFor(PendingUnreadableShare)
final pendingUnreadableShareProvider = PendingUnreadableShareProvider._();

/// Whether another app shared something with yamt that we could not read and
/// no page told the user yet.
final class PendingUnreadableShareProvider
    extends $NotifierProvider<PendingUnreadableShare, bool> {
  /// Whether another app shared something with yamt that we could not read and
  /// no page told the user yet.
  PendingUnreadableShareProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingUnreadableShareProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingUnreadableShareHash();

  @$internal
  @override
  PendingUnreadableShare create() => PendingUnreadableShare();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pendingUnreadableShareHash() =>
    r'80523313ce9d1af472e322acdb4a888a7767752c';

/// Whether another app shared something with yamt that we could not read and
/// no page told the user yet.

abstract class _$PendingUnreadableShare extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
