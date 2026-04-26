// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_balance_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie balance now.

@ProviderFor(calorieBalanceNow)
final calorieBalanceNowProvider = CalorieBalanceNowProvider._();

/// Calorie balance now.

final class CalorieBalanceNowProvider
    extends
        $FunctionalProvider<
          CalorieBalanceNow,
          CalorieBalanceNow,
          CalorieBalanceNow
        >
    with $Provider<CalorieBalanceNow> {
  /// Calorie balance now.
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

/// Calorie balance summary.

@ProviderFor(calorieBalanceSummary)
final calorieBalanceSummaryProvider = CalorieBalanceSummaryProvider._();

/// Calorie balance summary.

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
  /// Calorie balance summary.
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
    r'7615df4279052bddca2dca00ee39c13c6c724e96';
