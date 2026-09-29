// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_weight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Weight trend of the last four weeks with the goal weight and its forecast.

@ProviderFor(progressWeight)
final progressWeightProvider = ProgressWeightProvider._();

/// Weight trend of the last four weeks with the goal weight and its forecast.

final class ProgressWeightProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressWeight>,
          ProgressWeight,
          FutureOr<ProgressWeight>
        >
    with $FutureModifier<ProgressWeight>, $FutureProvider<ProgressWeight> {
  /// Weight trend of the last four weeks with the goal weight and its forecast.
  ProgressWeightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressWeightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressWeightHash();

  @$internal
  @override
  $FutureProviderElement<ProgressWeight> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressWeight> create(Ref ref) {
    return progressWeight(ref);
  }
}

String _$progressWeightHash() => r'a794ac2de4424fc6594592958d35526e9e0f9b7f';
