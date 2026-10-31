// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_all_macros_colored_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether every macro shows its color, instead of only the one with the
/// lowest share of its target. One choice for every design, saved on the
/// device; off by default.

@ProviderFor(AppAllMacrosColoredController)
final appAllMacrosColoredControllerProvider =
    AppAllMacrosColoredControllerProvider._();

/// Whether every macro shows its color, instead of only the one with the
/// lowest share of its target. One choice for every design, saved on the
/// device; off by default.
final class AppAllMacrosColoredControllerProvider
    extends $NotifierProvider<AppAllMacrosColoredController, bool> {
  /// Whether every macro shows its color, instead of only the one with the
  /// lowest share of its target. One choice for every design, saved on the
  /// device; off by default.
  AppAllMacrosColoredControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAllMacrosColoredControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAllMacrosColoredControllerHash();

  @$internal
  @override
  AppAllMacrosColoredController create() => AppAllMacrosColoredController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appAllMacrosColoredControllerHash() =>
    r'be33b4d4f5d43e733655b02f660cde4e3e281cb1';

/// Whether every macro shows its color, instead of only the one with the
/// lowest share of its target. One choice for every design, saved on the
/// device; off by default.

abstract class _$AppAllMacrosColoredController extends $Notifier<bool> {
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
