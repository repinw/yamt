// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current goal with the weight that counts now and today's targets.

@ProviderFor(progressGoal)
final progressGoalProvider = ProgressGoalProvider._();

/// The current goal with the weight that counts now and today's targets.

final class ProgressGoalProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressGoal>,
          ProgressGoal,
          FutureOr<ProgressGoal>
        >
    with $FutureModifier<ProgressGoal>, $FutureProvider<ProgressGoal> {
  /// The current goal with the weight that counts now and today's targets.
  ProgressGoalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressGoalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressGoalHash();

  @$internal
  @override
  $FutureProviderElement<ProgressGoal> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressGoal> create(Ref ref) {
    return progressGoal(ref);
  }
}

String _$progressGoalHash() => r'069d61d549ca92b06ea3ecb1f302a57314ed8262';
