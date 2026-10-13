// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_nutrition_target_resolver_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the resolved [DailyNutritionTargetResolver] implementation.

@ProviderFor(dailyNutritionTargetResolver)
final dailyNutritionTargetResolverProvider =
    DailyNutritionTargetResolverProvider._();

/// Provides the resolved [DailyNutritionTargetResolver] implementation.

final class DailyNutritionTargetResolverProvider
    extends
        $FunctionalProvider<
          DailyNutritionTargetResolver,
          DailyNutritionTargetResolver,
          DailyNutritionTargetResolver
        >
    with $Provider<DailyNutritionTargetResolver> {
  /// Provides the resolved [DailyNutritionTargetResolver] implementation.
  DailyNutritionTargetResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyNutritionTargetResolverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyNutritionTargetResolverHash();

  @$internal
  @override
  $ProviderElement<DailyNutritionTargetResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyNutritionTargetResolver create(Ref ref) {
    return dailyNutritionTargetResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyNutritionTargetResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyNutritionTargetResolver>(value),
    );
  }
}

String _$dailyNutritionTargetResolverHash() =>
    r'5f4240550a017a99f5e75e95642e5e06e62439e4';
