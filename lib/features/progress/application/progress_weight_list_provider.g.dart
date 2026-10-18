// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_weight_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every weighing of [range] with the trend, the goal starts, and the goal
/// weight.

@ProviderFor(progressWeightList)
final progressWeightListProvider = ProgressWeightListFamily._();

/// Every weighing of [range] with the trend, the goal starts, and the goal
/// weight.

final class ProgressWeightListProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressWeightList>,
          ProgressWeightList,
          FutureOr<ProgressWeightList>
        >
    with
        $FutureModifier<ProgressWeightList>,
        $FutureProvider<ProgressWeightList> {
  /// Every weighing of [range] with the trend, the goal starts, and the goal
  /// weight.
  ProgressWeightListProvider._({
    required ProgressWeightListFamily super.from,
    required ProgressWeightRange super.argument,
  }) : super(
         retry: null,
         name: r'progressWeightListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressWeightListHash();

  @override
  String toString() {
    return r'progressWeightListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressWeightList> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressWeightList> create(Ref ref) {
    final argument = this.argument as ProgressWeightRange;
    return progressWeightList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressWeightListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressWeightListHash() =>
    r'd71e0358187cc7a08ea0880730105c55e87695d0';

/// Every weighing of [range] with the trend, the goal starts, and the goal
/// weight.

final class ProgressWeightListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ProgressWeightList>,
          ProgressWeightRange
        > {
  ProgressWeightListFamily._()
    : super(
        retry: null,
        name: r'progressWeightListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every weighing of [range] with the trend, the goal starts, and the goal
  /// weight.

  ProgressWeightListProvider call(ProgressWeightRange range) =>
      ProgressWeightListProvider._(argument: range, from: this);

  @override
  String toString() => r'progressWeightListProvider';
}
