// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_recent_colors_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The colors the user last took in the color picker, newest first, saved
/// on the device.

@ProviderFor(AppRecentColorsController)
final appRecentColorsControllerProvider = AppRecentColorsControllerProvider._();

/// The colors the user last took in the color picker, newest first, saved
/// on the device.
final class AppRecentColorsControllerProvider
    extends $NotifierProvider<AppRecentColorsController, List<Color>> {
  /// The colors the user last took in the color picker, newest first, saved
  /// on the device.
  AppRecentColorsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRecentColorsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRecentColorsControllerHash();

  @$internal
  @override
  AppRecentColorsController create() => AppRecentColorsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Color> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Color>>(value),
    );
  }
}

String _$appRecentColorsControllerHash() =>
    r'cf8cdd38c8640563afbbe51ffa56338977c9e160';

/// The colors the user last took in the color picker, newest first, saved
/// on the device.

abstract class _$AppRecentColorsController extends $Notifier<List<Color>> {
  List<Color> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Color>, List<Color>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Color>, List<Color>>,
              List<Color>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
