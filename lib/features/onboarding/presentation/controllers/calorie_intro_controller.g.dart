// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_intro_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State controller for the calorie onboarding intro.

@ProviderFor(CalorieIntroController)
final calorieIntroControllerProvider = CalorieIntroControllerProvider._();

/// State controller for the calorie onboarding intro.
final class CalorieIntroControllerProvider
    extends $NotifierProvider<CalorieIntroController, CalorieIntroState> {
  /// State controller for the calorie onboarding intro.
  CalorieIntroControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieIntroControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieIntroControllerHash();

  @$internal
  @override
  CalorieIntroController create() => CalorieIntroController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieIntroState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieIntroState>(value),
    );
  }
}

String _$calorieIntroControllerHash() =>
    r'cdcee93964219c1b22b8efd97199315cf41d7135';

/// State controller for the calorie onboarding intro.

abstract class _$CalorieIntroController extends $Notifier<CalorieIntroState> {
  CalorieIntroState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalorieIntroState, CalorieIntroState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalorieIntroState, CalorieIntroState>,
              CalorieIntroState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
