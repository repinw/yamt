// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_plan_color_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan color the user picked, used in light and dark alike. The choice
/// is saved on the device; null means the Graphit plan brown of each
/// brightness.

@ProviderFor(AppPlanColorController)
final appPlanColorControllerProvider = AppPlanColorControllerProvider._();

/// The plan color the user picked, used in light and dark alike. The choice
/// is saved on the device; null means the Graphit plan brown of each
/// brightness.
final class AppPlanColorControllerProvider
    extends $NotifierProvider<AppPlanColorController, Color?> {
  /// The plan color the user picked, used in light and dark alike. The choice
  /// is saved on the device; null means the Graphit plan brown of each
  /// brightness.
  AppPlanColorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPlanColorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPlanColorControllerHash();

  @$internal
  @override
  AppPlanColorController create() => AppPlanColorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color?>(value),
    );
  }
}

String _$appPlanColorControllerHash() =>
    r'011e7d8da0ebc8b2fae20568d01742656a491414';

/// The plan color the user picked, used in light and dark alike. The choice
/// is saved on the device; null means the Graphit plan brown of each
/// brightness.

abstract class _$AppPlanColorController extends $Notifier<Color?> {
  Color? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Color?, Color?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color?, Color?>,
              Color?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
