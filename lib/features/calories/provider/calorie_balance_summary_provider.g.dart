// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_balance_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'35b0dc864073fb3d59962719561e9ad9091a8171';
