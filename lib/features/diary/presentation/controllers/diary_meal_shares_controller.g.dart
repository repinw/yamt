// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_shares_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the user splits the day's kcal over the meals, saved on the device.

@ProviderFor(DiaryMealSharesController)
final diaryMealSharesControllerProvider = DiaryMealSharesControllerProvider._();

/// How the user splits the day's kcal over the meals, saved on the device.
final class DiaryMealSharesControllerProvider
    extends $NotifierProvider<DiaryMealSharesController, DiaryMealShares> {
  /// How the user splits the day's kcal over the meals, saved on the device.
  DiaryMealSharesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryMealSharesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryMealSharesControllerHash();

  @$internal
  @override
  DiaryMealSharesController create() => DiaryMealSharesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryMealShares value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryMealShares>(value),
    );
  }
}

String _$diaryMealSharesControllerHash() =>
    r'558da02bd9b6d75bbaed798f2ff747fb687e0741';

/// How the user splits the day's kcal over the meals, saved on the device.

abstract class _$DiaryMealSharesController extends $Notifier<DiaryMealShares> {
  DiaryMealShares build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryMealShares, DiaryMealShares>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryMealShares, DiaryMealShares>,
              DiaryMealShares,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
