// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tdee_analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides fully resolved TDEE analytics state for charts and insights.

@ProviderFor(tdeeAnalytics)
final tdeeAnalyticsProvider = TdeeAnalyticsFamily._();

/// Provides fully resolved TDEE analytics state for charts and insights.

final class TdeeAnalyticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TdeeAnalyticsState>,
          TdeeAnalyticsState,
          FutureOr<TdeeAnalyticsState>
        >
    with
        $FutureModifier<TdeeAnalyticsState>,
        $FutureProvider<TdeeAnalyticsState> {
  /// Provides fully resolved TDEE analytics state for charts and insights.
  TdeeAnalyticsProvider._({
    required TdeeAnalyticsFamily super.from,
    required TdeeAnalyticsQuery super.argument,
  }) : super(
         retry: null,
         name: r'tdeeAnalyticsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tdeeAnalyticsHash();

  @override
  String toString() {
    return r'tdeeAnalyticsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TdeeAnalyticsState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TdeeAnalyticsState> create(Ref ref) {
    final argument = this.argument as TdeeAnalyticsQuery;
    return tdeeAnalytics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TdeeAnalyticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tdeeAnalyticsHash() => r'6901671ce5978b157b963776c19d8aba89db671c';

/// Provides fully resolved TDEE analytics state for charts and insights.

final class TdeeAnalyticsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TdeeAnalyticsState>,
          TdeeAnalyticsQuery
        > {
  TdeeAnalyticsFamily._()
    : super(
        retry: null,
        name: r'tdeeAnalyticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides fully resolved TDEE analytics state for charts and insights.

  TdeeAnalyticsProvider call(TdeeAnalyticsQuery query) =>
      TdeeAnalyticsProvider._(argument: query, from: this);

  @override
  String toString() => r'tdeeAnalyticsProvider';
}
