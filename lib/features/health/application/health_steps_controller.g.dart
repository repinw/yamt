// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_steps_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app shows the user's steps, saved on the device. Off until the
/// user turns it on; turning it on connects Health when needed and asks for
/// the steps permission. Disconnecting Health turns it off.

@ProviderFor(HealthStepsController)
final healthStepsControllerProvider = HealthStepsControllerProvider._();

/// Whether the app shows the user's steps, saved on the device. Off until the
/// user turns it on; turning it on connects Health when needed and asks for
/// the steps permission. Disconnecting Health turns it off.
final class HealthStepsControllerProvider
    extends $NotifierProvider<HealthStepsController, bool> {
  /// Whether the app shows the user's steps, saved on the device. Off until the
  /// user turns it on; turning it on connects Health when needed and asks for
  /// the steps permission. Disconnecting Health turns it off.
  HealthStepsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthStepsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthStepsControllerHash();

  @$internal
  @override
  HealthStepsController create() => HealthStepsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$healthStepsControllerHash() =>
    r'5a74d067f9a1bef7c0f1949bd6d0c3bc5eb529d0';

/// Whether the app shows the user's steps, saved on the device. Off until the
/// user turns it on; turning it on connects Health when needed and asks for
/// the steps permission. Disconnecting Health turns it off.

abstract class _$HealthStepsController extends $Notifier<bool> {
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
