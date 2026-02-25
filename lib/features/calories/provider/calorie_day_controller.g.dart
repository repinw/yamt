// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_day_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalorieDayController)
final calorieDayControllerProvider = CalorieDayControllerProvider._();

final class CalorieDayControllerProvider
    extends $NotifierProvider<CalorieDayController, DateTime> {
  CalorieDayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieDayControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieDayControllerHash();

  @$internal
  @override
  CalorieDayController create() => CalorieDayController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$calorieDayControllerHash() =>
    r'2494fa7c0925db9999dfe461ed02388dc337f62c';

abstract class _$CalorieDayController extends $Notifier<DateTime> {
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
