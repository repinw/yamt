// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_intake_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Intake of the current 7-day run and, by day type, of the period of
/// [scope].
///
/// Logging, editing, or removing an entry refreshes it through the calorie
/// overview revision.

@ProviderFor(progressIntake)
final progressIntakeProvider = ProgressIntakeFamily._();

/// Intake of the current 7-day run and, by day type, of the period of
/// [scope].
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
  /// Intake of the current 7-day run and, by day type, of the period of
  /// [scope].
  ///
  /// Logging, editing, or removing an entry refreshes it through the calorie
  /// overview revision.
  ProgressIntakeProvider._({
    required ProgressIntakeFamily super.from,
    required ProgressScope super.argument,
  }) : super(
         retry: null,
         name: r'progressIntakeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressIntakeHash();

  @override
  String toString() {
    return r'progressIntakeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressIntake> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressIntake> create(Ref ref) {
    final argument = this.argument as ProgressScope;
    return progressIntake(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressIntakeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressIntakeHash() => r'7d3f6ba53e4b2726d4f540ac86abb9c94897ac73';

/// Intake of the current 7-day run and, by day type, of the period of
/// [scope].
///
/// Logging, editing, or removing an entry refreshes it through the calorie
/// overview revision.

final class ProgressIntakeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProgressIntake>, ProgressScope> {
  ProgressIntakeFamily._()
    : super(
        retry: null,
        name: r'progressIntakeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Intake of the current 7-day run and, by day type, of the period of
  /// [scope].
  ///
  /// Logging, editing, or removing an entry refreshes it through the calorie
  /// overview revision.

  ProgressIntakeProvider call(ProgressScope scope) =>
      ProgressIntakeProvider._(argument: scope, from: this);

  @override
  String toString() => r'progressIntakeProvider';
}
