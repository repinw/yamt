// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_accent_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The accent color the user picked. The choice is saved on the device;
/// without one, or with one this version does not know, the app uses lime.

@ProviderFor(AppAccentController)
final appAccentControllerProvider = AppAccentControllerProvider._();

/// The accent color the user picked. The choice is saved on the device;
/// without one, or with one this version does not know, the app uses lime.
final class AppAccentControllerProvider
    extends $NotifierProvider<AppAccentController, AppAccent> {
  /// The accent color the user picked. The choice is saved on the device;
  /// without one, or with one this version does not know, the app uses lime.
  AppAccentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAccentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAccentControllerHash();

  @$internal
  @override
  AppAccentController create() => AppAccentController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAccent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAccent>(value),
    );
  }
}

String _$appAccentControllerHash() =>
    r'0391555aae46f1f2eb8784de9153bfc819667068';

/// The accent color the user picked. The choice is saved on the device;
/// without one, or with one this version does not know, the app uses lime.

abstract class _$AppAccentController extends $Notifier<AppAccent> {
  AppAccent build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppAccent, AppAccent>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppAccent, AppAccent>,
              AppAccent,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
