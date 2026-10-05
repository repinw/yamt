// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app is light, dark, or follows the system. The choice is
/// saved on the device; without one the app follows the system.

@ProviderFor(AppThemeModeController)
final appThemeModeControllerProvider = AppThemeModeControllerProvider._();

/// Whether the app is light, dark, or follows the system. The choice is
/// saved on the device; without one the app follows the system.
final class AppThemeModeControllerProvider
    extends $NotifierProvider<AppThemeModeController, ThemeMode> {
  /// Whether the app is light, dark, or follows the system. The choice is
  /// saved on the device; without one the app follows the system.
  AppThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeControllerHash();

  @$internal
  @override
  AppThemeModeController create() => AppThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeControllerHash() =>
    r'beb928b3e64a576dbd556acf971409cc6c9688e9';

/// Whether the app is light, dark, or follows the system. The choice is
/// saved on the device; without one the app follows the system.

abstract class _$AppThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
