// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_hint_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The newer version that the "update available" hint still has to name,
/// or null. The hint shows once per newer version on this device.

@ProviderFor(AppUpdateHintController)
final appUpdateHintControllerProvider = AppUpdateHintControllerProvider._();

/// The newer version that the "update available" hint still has to name,
/// or null. The hint shows once per newer version on this device.
final class AppUpdateHintControllerProvider
    extends $AsyncNotifierProvider<AppUpdateHintController, AppVersion?> {
  /// The newer version that the "update available" hint still has to name,
  /// or null. The hint shows once per newer version on this device.
  AppUpdateHintControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateHintControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateHintControllerHash();

  @$internal
  @override
  AppUpdateHintController create() => AppUpdateHintController();
}

String _$appUpdateHintControllerHash() =>
    r'f21e6b52c0eed1371e089ab698d1ea984822a342';

/// The newer version that the "update available" hint still has to name,
/// or null. The hint shows once per newer version on this device.

abstract class _$AppUpdateHintController extends $AsyncNotifier<AppVersion?> {
  FutureOr<AppVersion?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppVersion?>, AppVersion?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppVersion?>, AppVersion?>,
              AsyncValue<AppVersion?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
