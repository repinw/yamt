// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The progress photos of [scope]: those of the current or of one past goal,
/// or all photos, also those from before the first goal.

@ProviderFor(progressPhotoOverview)
final progressPhotoOverviewProvider = ProgressPhotoOverviewFamily._();

/// The progress photos of [scope]: those of the current or of one past goal,
/// or all photos, also those from before the first goal.

final class ProgressPhotoOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressPhotoOverview>,
          ProgressPhotoOverview,
          FutureOr<ProgressPhotoOverview>
        >
    with
        $FutureModifier<ProgressPhotoOverview>,
        $FutureProvider<ProgressPhotoOverview> {
  /// The progress photos of [scope]: those of the current or of one past goal,
  /// or all photos, also those from before the first goal.
  ProgressPhotoOverviewProvider._({
    required ProgressPhotoOverviewFamily super.from,
    required ProgressScope super.argument,
  }) : super(
         retry: null,
         name: r'progressPhotoOverviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoOverviewHash();

  @override
  String toString() {
    return r'progressPhotoOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProgressPhotoOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressPhotoOverview> create(Ref ref) {
    final argument = this.argument as ProgressScope;
    return progressPhotoOverview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressPhotoOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressPhotoOverviewHash() =>
    r'a8404f7237e24970485145cf1a66231999111313';

/// The progress photos of [scope]: those of the current or of one past goal,
/// or all photos, also those from before the first goal.

final class ProgressPhotoOverviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ProgressPhotoOverview>,
          ProgressScope
        > {
  ProgressPhotoOverviewFamily._()
    : super(
        retry: null,
        name: r'progressPhotoOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The progress photos of [scope]: those of the current or of one past goal,
  /// or all photos, also those from before the first goal.

  ProgressPhotoOverviewProvider call(ProgressScope scope) =>
      ProgressPhotoOverviewProvider._(argument: scope, from: this);

  @override
  String toString() => r'progressPhotoOverviewProvider';
}
