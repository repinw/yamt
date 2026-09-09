// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tdee_analytics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing UI filter selections for TDEE analytics.

@ProviderFor(TdeeAnalyticsController)
final tdeeAnalyticsControllerProvider = TdeeAnalyticsControllerProvider._();

/// Controller managing UI filter selections for TDEE analytics.
final class TdeeAnalyticsControllerProvider
    extends $NotifierProvider<TdeeAnalyticsController, TdeeAnalyticsUiState> {
  /// Controller managing UI filter selections for TDEE analytics.
  TdeeAnalyticsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tdeeAnalyticsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tdeeAnalyticsControllerHash();

  @$internal
  @override
  TdeeAnalyticsController create() => TdeeAnalyticsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TdeeAnalyticsUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TdeeAnalyticsUiState>(value),
    );
  }
}

String _$tdeeAnalyticsControllerHash() =>
    r'c8217d2e3f3f157baedf23427f9e121cb625346a';

/// Controller managing UI filter selections for TDEE analytics.

abstract class _$TdeeAnalyticsController
    extends $Notifier<TdeeAnalyticsUiState> {
  TdeeAnalyticsUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TdeeAnalyticsUiState, TdeeAnalyticsUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TdeeAnalyticsUiState, TdeeAnalyticsUiState>,
              TdeeAnalyticsUiState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
