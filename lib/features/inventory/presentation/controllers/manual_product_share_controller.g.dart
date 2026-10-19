// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_product_share_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shares a manually saved product with other users in the background.

@ProviderFor(ManualProductShareController)
final manualProductShareControllerProvider =
    ManualProductShareControllerProvider._();

/// Shares a manually saved product with other users in the background.
final class ManualProductShareControllerProvider
    extends $AsyncNotifierProvider<ManualProductShareController, void> {
  /// Shares a manually saved product with other users in the background.
  ManualProductShareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualProductShareControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualProductShareControllerHash();

  @$internal
  @override
  ManualProductShareController create() => ManualProductShareController();
}

String _$manualProductShareControllerHash() =>
    r'325cf09c9c5854e06bae831e3086882e1460a8a3';

/// Shares a manually saved product with other users in the background.

abstract class _$ManualProductShareController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
