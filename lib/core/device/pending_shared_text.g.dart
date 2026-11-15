// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_shared_text.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Text that another app shared with yamt and that no page took yet.

@ProviderFor(PendingSharedText)
final pendingSharedTextProvider = PendingSharedTextProvider._();

/// Text that another app shared with yamt and that no page took yet.
final class PendingSharedTextProvider
    extends $NotifierProvider<PendingSharedText, String?> {
  /// Text that another app shared with yamt and that no page took yet.
  PendingSharedTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSharedTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSharedTextHash();

  @$internal
  @override
  PendingSharedText create() => PendingSharedText();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingSharedTextHash() => r'10554834efa12743882718ee1d366667eec24e37';

/// Text that another app shared with yamt and that no page took yet.

abstract class _$PendingSharedText extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
