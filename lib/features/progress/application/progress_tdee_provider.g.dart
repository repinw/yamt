// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_tdee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TDEE per confirmed weekly check-in of the current goal.

@ProviderFor(progressTdee)
final progressTdeeProvider = ProgressTdeeProvider._();

/// TDEE per confirmed weekly check-in of the current goal.

final class ProgressTdeeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressTdee>,
          ProgressTdee,
          FutureOr<ProgressTdee>
        >
    with $FutureModifier<ProgressTdee>, $FutureProvider<ProgressTdee> {
  /// TDEE per confirmed weekly check-in of the current goal.
  ProgressTdeeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressTdeeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressTdeeHash();

  @$internal
  @override
  $FutureProviderElement<ProgressTdee> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressTdee> create(Ref ref) {
    return progressTdee(ref);
  }
}

String _$progressTdeeHash() => r'0849080e7ff5598916b5109f1d498867691e2a3e';
