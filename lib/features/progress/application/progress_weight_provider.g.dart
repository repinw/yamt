// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_weight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Weight trend of the period of [scope] with the goal starts and the
/// forecast for the goal weight.

@ProviderFor(progressWeight)
final progressWeightProvider = ProgressWeightFamily._();

/// Weight trend of the period of [scope] with the goal starts and the
/// forecast for the goal weight.

final class ProgressWeightProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressWeight>,
          ProgressWeight,
          FutureOr<ProgressWeight>
        >
    with $FutureModifier<ProgressWeight>, $FutureProvider<ProgressWeight> {
  /// Weight trend of the period of [scope] with the goal starts and the
  /// forecast for the goal weight.
  ProgressWeightProvider._({
    required ProgressWeightFamily super.from,
    required ProgressScope super.argument,
  }) : super(
         retry: null,
         name: r'progressWeightProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressWeightHash();

  @override
  String toString() {
    return r'progressWeightProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressWeight> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressWeight> create(Ref ref) {
    final argument = this.argument as ProgressScope;
    return progressWeight(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressWeightProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressWeightHash() => r'54805edb290b05ab77b6831ada65b798c5551cdf';

/// Weight trend of the period of [scope] with the goal starts and the
/// forecast for the goal weight.

final class ProgressWeightFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProgressWeight>, ProgressScope> {
  ProgressWeightFamily._()
    : super(
        retry: null,
        name: r'progressWeightProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Weight trend of the period of [scope] with the goal starts and the
  /// forecast for the goal weight.

  ProgressWeightProvider call(ProgressScope scope) =>
      ProgressWeightProvider._(argument: scope, from: this);

  @override
  String toString() => r'progressWeightProvider';
}
