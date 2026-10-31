// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_design_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The design the user picked. The choice is saved on the device; without
/// one the app follows the system.

@ProviderFor(AppDesignController)
final appDesignControllerProvider = AppDesignControllerProvider._();

/// The design the user picked. The choice is saved on the device; without
/// one the app follows the system.
final class AppDesignControllerProvider
    extends $NotifierProvider<AppDesignController, AppDesign> {
  /// The design the user picked. The choice is saved on the device; without
  /// one the app follows the system.
  AppDesignControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDesignControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDesignControllerHash();

  @$internal
  @override
  AppDesignController create() => AppDesignController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDesign value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDesign>(value),
    );
  }
}

String _$appDesignControllerHash() =>
    r'ad7d3ca8c49e5fa28f63d6b1cf8667a622ded35e';

/// The design the user picked. The choice is saved on the device; without
/// one the app follows the system.

abstract class _$AppDesignController extends $Notifier<AppDesign> {
  AppDesign build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppDesign, AppDesign>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppDesign, AppDesign>,
              AppDesign,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
