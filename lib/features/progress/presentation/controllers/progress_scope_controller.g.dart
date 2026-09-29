// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_scope_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which goals the Fortschritt tab shows: the current one or all.

@ProviderFor(ProgressScopeController)
final progressScopeControllerProvider = ProgressScopeControllerProvider._();

/// Which goals the Fortschritt tab shows: the current one or all.
final class ProgressScopeControllerProvider
    extends $NotifierProvider<ProgressScopeController, ProgressScope> {
  /// Which goals the Fortschritt tab shows: the current one or all.
  ProgressScopeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressScopeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressScopeControllerHash();

  @$internal
  @override
  ProgressScopeController create() => ProgressScopeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressScope>(value),
    );
  }
}

String _$progressScopeControllerHash() =>
    r'd0b14a0e2550756378ccbe01fed7be324f40537c';

/// Which goals the Fortschritt tab shows: the current one or all.

abstract class _$ProgressScopeController extends $Notifier<ProgressScope> {
  ProgressScope build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProgressScope, ProgressScope>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressScope, ProgressScope>,
              ProgressScope,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
