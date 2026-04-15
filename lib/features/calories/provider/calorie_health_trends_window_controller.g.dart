// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_trends_window_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalorieHealthTrendsWindowController)
final calorieHealthTrendsWindowControllerProvider =
    CalorieHealthTrendsWindowControllerProvider._();

final class CalorieHealthTrendsWindowControllerProvider
    extends $NotifierProvider<CalorieHealthTrendsWindowController, DateTime?> {
  CalorieHealthTrendsWindowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieHealthTrendsWindowControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$calorieHealthTrendsWindowControllerHash();

  @$internal
  @override
  CalorieHealthTrendsWindowController create() =>
      CalorieHealthTrendsWindowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$calorieHealthTrendsWindowControllerHash() =>
    r'5cbaa86d563f01eb0f1f44daa08724b141f61d0a';

abstract class _$CalorieHealthTrendsWindowController
    extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
