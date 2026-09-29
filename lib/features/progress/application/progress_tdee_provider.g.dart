// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_tdee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// TDEE per confirmed weekly check-in of the goals of [scope].

@ProviderFor(progressTdee)
final progressTdeeProvider = ProgressTdeeFamily._();

/// TDEE per confirmed weekly check-in of the goals of [scope].

final class ProgressTdeeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressTdee>,
          ProgressTdee,
          FutureOr<ProgressTdee>
        >
    with $FutureModifier<ProgressTdee>, $FutureProvider<ProgressTdee> {
  /// TDEE per confirmed weekly check-in of the goals of [scope].
  ProgressTdeeProvider._({
    required ProgressTdeeFamily super.from,
    required ProgressScope super.argument,
  }) : super(
         retry: null,
         name: r'progressTdeeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressTdeeHash();

  @override
  String toString() {
    return r'progressTdeeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressTdee> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressTdee> create(Ref ref) {
    final argument = this.argument as ProgressScope;
    return progressTdee(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressTdeeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressTdeeHash() => r'6e14d57077124c531f4e06543d0131214822d399';

/// TDEE per confirmed weekly check-in of the goals of [scope].

final class ProgressTdeeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProgressTdee>, ProgressScope> {
  ProgressTdeeFamily._()
    : super(
        retry: null,
        name: r'progressTdeeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// TDEE per confirmed weekly check-in of the goals of [scope].

  ProgressTdeeProvider call(ProgressScope scope) =>
      ProgressTdeeProvider._(argument: scope, from: this);

  @override
  String toString() => r'progressTdeeProvider';
}
