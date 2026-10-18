// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_tdee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Daily TDEE of the period of [scope] with its check-ins.

@ProviderFor(progressTdee)
final progressTdeeProvider = ProgressTdeeFamily._();

/// Daily TDEE of the period of [scope] with its check-ins.

final class ProgressTdeeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressTdee>,
          ProgressTdee,
          FutureOr<ProgressTdee>
        >
    with $FutureModifier<ProgressTdee>, $FutureProvider<ProgressTdee> {
  /// Daily TDEE of the period of [scope] with its check-ins.
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

String _$progressTdeeHash() => r'b27984fd5cb3738e1ac4effcdf11d5f3e8921d5f';

/// Daily TDEE of the period of [scope] with its check-ins.

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

  /// Daily TDEE of the period of [scope] with its check-ins.

  ProgressTdeeProvider call(ProgressScope scope) =>
      ProgressTdeeProvider._(argument: scope, from: this);

  @override
  String toString() => r'progressTdeeProvider';
}
