// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_intake_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Intake of the current 7-day run and of the last four weeks.
///
/// Logging, editing, or removing an entry refreshes it through the calorie
/// overview revision.

@ProviderFor(progressIntake)
final progressIntakeProvider = ProgressIntakeProvider._();

/// Intake of the current 7-day run and of the last four weeks.
///
/// Logging, editing, or removing an entry refreshes it through the calorie
/// overview revision.

final class ProgressIntakeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressIntake>,
          ProgressIntake,
          FutureOr<ProgressIntake>
        >
    with $FutureModifier<ProgressIntake>, $FutureProvider<ProgressIntake> {
  /// Intake of the current 7-day run and of the last four weeks.
  ///
  /// Logging, editing, or removing an entry refreshes it through the calorie
  /// overview revision.
  ProgressIntakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressIntakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressIntakeHash();

  @$internal
  @override
  $FutureProviderElement<ProgressIntake> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressIntake> create(Ref ref) {
    return progressIntake(ref);
  }
}

String _$progressIntakeHash() => r'498d8c2c60aaf83edb0691216f9183bd39276104';
