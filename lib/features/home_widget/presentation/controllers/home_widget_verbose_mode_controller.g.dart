// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_verbose_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the home-screen widget shows its verbose layout (eaten / target
/// grams next to each macro bar, like the expanded Diary card) instead of
/// the silent one. The choice is saved on the device.

@ProviderFor(HomeWidgetVerboseModeController)
final homeWidgetVerboseModeControllerProvider =
    HomeWidgetVerboseModeControllerProvider._();

/// Whether the home-screen widget shows its verbose layout (eaten / target
/// grams next to each macro bar, like the expanded Diary card) instead of
/// the silent one. The choice is saved on the device.
final class HomeWidgetVerboseModeControllerProvider
    extends $NotifierProvider<HomeWidgetVerboseModeController, bool> {
  /// Whether the home-screen widget shows its verbose layout (eaten / target
  /// grams next to each macro bar, like the expanded Diary card) instead of
  /// the silent one. The choice is saved on the device.
  HomeWidgetVerboseModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetVerboseModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetVerboseModeControllerHash();

  @$internal
  @override
  HomeWidgetVerboseModeController create() => HomeWidgetVerboseModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$homeWidgetVerboseModeControllerHash() =>
    r'9445e8d2f31eb84662fd99b2e7f164e0207df7f9';

/// Whether the home-screen widget shows its verbose layout (eaten / target
/// grams next to each macro bar, like the expanded Diary card) instead of
/// the silent one. The choice is saved on the device.

abstract class _$HomeWidgetVerboseModeController extends $Notifier<bool> {
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
