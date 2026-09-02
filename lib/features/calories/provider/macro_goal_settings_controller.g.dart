// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macro_goal_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages persisted macro goal settings.

@ProviderFor(MacroGoalSettingsController)
final macroGoalSettingsControllerProvider =
    MacroGoalSettingsControllerProvider._();

/// Manages persisted macro goal settings.
final class MacroGoalSettingsControllerProvider
    extends $NotifierProvider<MacroGoalSettingsController, MacroGoalSettings> {
  /// Manages persisted macro goal settings.
  MacroGoalSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'macroGoalSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$macroGoalSettingsControllerHash();

  @$internal
  @override
  MacroGoalSettingsController create() => MacroGoalSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MacroGoalSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MacroGoalSettings>(value),
    );
  }
}

String _$macroGoalSettingsControllerHash() =>
    r'0401252b30d574039192298ff97db84615e2c3db';

/// Manages persisted macro goal settings.

abstract class _$MacroGoalSettingsController
    extends $Notifier<MacroGoalSettings> {
  MacroGoalSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MacroGoalSettings, MacroGoalSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MacroGoalSettings, MacroGoalSettings>,
              MacroGoalSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
