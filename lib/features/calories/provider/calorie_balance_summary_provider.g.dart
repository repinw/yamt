// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_balance_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieBalanceNow)
final calorieBalanceNowProvider = CalorieBalanceNowProvider._();

final class CalorieBalanceNowProvider
    extends
        $FunctionalProvider<
          CalorieBalanceNow,
          CalorieBalanceNow,
          CalorieBalanceNow
        >
    with $Provider<CalorieBalanceNow> {
  CalorieBalanceNowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBalanceNowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBalanceNowHash();

  @$internal
  @override
  $ProviderElement<CalorieBalanceNow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieBalanceNow create(Ref ref) {
    return calorieBalanceNow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieBalanceNow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieBalanceNow>(value),
    );
  }
}

String _$calorieBalanceNowHash() => r'3cb71b22b7ddee933f84bad12ae8fab5150305ac';

@ProviderFor(calorieBalanceSummary)
final calorieBalanceSummaryProvider = CalorieBalanceSummaryProvider._();

final class CalorieBalanceSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieBalanceSummaryData>,
          CalorieBalanceSummaryData,
          FutureOr<CalorieBalanceSummaryData>
        >
    with
        $FutureModifier<CalorieBalanceSummaryData>,
        $FutureProvider<CalorieBalanceSummaryData> {
  CalorieBalanceSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBalanceSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBalanceSummaryHash();

  @$internal
  @override
  $FutureProviderElement<CalorieBalanceSummaryData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieBalanceSummaryData> create(Ref ref) {
    return calorieBalanceSummary(ref);
  }
}

String _$calorieBalanceSummaryHash() =>
    r'614086e642978641cfcddbb3d89fb3498e31fc6e';
