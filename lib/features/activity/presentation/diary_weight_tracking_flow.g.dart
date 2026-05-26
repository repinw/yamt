// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weight_tracking_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the Activity-owned diary weight tracking flow.

@ProviderFor(diaryWeightTrackingFlow)
final diaryWeightTrackingFlowProvider = DiaryWeightTrackingFlowProvider._();

/// Provides the Activity-owned diary weight tracking flow.

final class DiaryWeightTrackingFlowProvider
    extends
        $FunctionalProvider<
          DiaryWeightTrackingFlow,
          DiaryWeightTrackingFlow,
          DiaryWeightTrackingFlow
        >
    with $Provider<DiaryWeightTrackingFlow> {
  /// Provides the Activity-owned diary weight tracking flow.
  DiaryWeightTrackingFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeightTrackingFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeightTrackingFlowHash();

  @$internal
  @override
  $ProviderElement<DiaryWeightTrackingFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryWeightTrackingFlow create(Ref ref) {
    return diaryWeightTrackingFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryWeightTrackingFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryWeightTrackingFlow>(value),
    );
  }
}

String _$diaryWeightTrackingFlowHash() =>
    r'b53eaa9d9d1606f12e99888d23b3f3e698317320';
