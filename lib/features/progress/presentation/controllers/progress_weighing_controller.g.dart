// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_weighing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Changes, deletes, and ignores one weighing of the weight list. Each
/// action returns whether it worked and refreshes what depends on the
/// weight.

@ProviderFor(ProgressWeighingController)
final progressWeighingControllerProvider =
    ProgressWeighingControllerProvider._();

/// Changes, deletes, and ignores one weighing of the weight list. Each
/// action returns whether it worked and refreshes what depends on the
/// weight.
final class ProgressWeighingControllerProvider
    extends $AsyncNotifierProvider<ProgressWeighingController, void> {
  /// Changes, deletes, and ignores one weighing of the weight list. Each
  /// action returns whether it worked and refreshes what depends on the
  /// weight.
  ProgressWeighingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressWeighingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressWeighingControllerHash();

  @$internal
  @override
  ProgressWeighingController create() => ProgressWeighingController();
}

String _$progressWeighingControllerHash() =>
    r'8d32155e22a7fc53abf687ee7ef3453f100bbe23';

/// Changes, deletes, and ignores one weighing of the weight list. Each
/// action returns whether it worked and refreshes what depends on the
/// weight.

abstract class _$ProgressWeighingController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
