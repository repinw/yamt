// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_visible_window_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalorieVisibleWindowController)
final calorieVisibleWindowControllerProvider =
    CalorieVisibleWindowControllerProvider._();

final class CalorieVisibleWindowControllerProvider
    extends $NotifierProvider<CalorieVisibleWindowController, DateTime> {
  CalorieVisibleWindowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieVisibleWindowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieVisibleWindowControllerHash();

  @$internal
  @override
  CalorieVisibleWindowController create() => CalorieVisibleWindowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$calorieVisibleWindowControllerHash() =>
    r'7079a54d9164464d711cf2476013548787b19769';

abstract class _$CalorieVisibleWindowController extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
