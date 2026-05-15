// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_activity_weight_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the diary activity weight aggregation service.

@ProviderFor(diaryActivityWeightService)
final diaryActivityWeightServiceProvider =
    DiaryActivityWeightServiceProvider._();

/// Provides the diary activity weight aggregation service.

final class DiaryActivityWeightServiceProvider
    extends
        $FunctionalProvider<
          DiaryActivityWeightService,
          DiaryActivityWeightService,
          DiaryActivityWeightService
        >
    with $Provider<DiaryActivityWeightService> {
  /// Provides the diary activity weight aggregation service.
  DiaryActivityWeightServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryActivityWeightServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryActivityWeightServiceHash();

  @$internal
  @override
  $ProviderElement<DiaryActivityWeightService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryActivityWeightService create(Ref ref) {
    return diaryActivityWeightService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryActivityWeightService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryActivityWeightService>(value),
    );
  }
}

String _$diaryActivityWeightServiceHash() =>
    r'5c8d86d2d3df8da609bb233db3f781c3d9194c19';
