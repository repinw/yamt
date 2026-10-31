// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_custom_colors_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The colors of the design "Individuell", saved on the device. Null until
/// the user first picks the design.

@ProviderFor(AppCustomColorsController)
final appCustomColorsControllerProvider = AppCustomColorsControllerProvider._();

/// The colors of the design "Individuell", saved on the device. Null until
/// the user first picks the design.
final class AppCustomColorsControllerProvider
    extends $NotifierProvider<AppCustomColorsController, AppCustomColors?> {
  /// The colors of the design "Individuell", saved on the device. Null until
  /// the user first picks the design.
  AppCustomColorsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appCustomColorsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appCustomColorsControllerHash();

  @$internal
  @override
  AppCustomColorsController create() => AppCustomColorsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppCustomColors? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppCustomColors?>(value),
    );
  }
}

String _$appCustomColorsControllerHash() =>
    r'3c8aa5172ed29652a26a8a0eead782343af04457';

/// The colors of the design "Individuell", saved on the device. Null until
/// the user first picks the design.

abstract class _$AppCustomColorsController extends $Notifier<AppCustomColors?> {
  AppCustomColors? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppCustomColors?, AppCustomColors?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppCustomColors?, AppCustomColors?>,
              AppCustomColors?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
