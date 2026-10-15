// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_capture_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Takes or picks a progress photo and saves it.

@ProviderFor(ProgressPhotoCaptureController)
final progressPhotoCaptureControllerProvider =
    ProgressPhotoCaptureControllerProvider._();

/// Takes or picks a progress photo and saves it.
final class ProgressPhotoCaptureControllerProvider
    extends $AsyncNotifierProvider<ProgressPhotoCaptureController, void> {
  /// Takes or picks a progress photo and saves it.
  ProgressPhotoCaptureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotoCaptureControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoCaptureControllerHash();

  @$internal
  @override
  ProgressPhotoCaptureController create() => ProgressPhotoCaptureController();
}

String _$progressPhotoCaptureControllerHash() =>
    r'5d9dc17e4e7b1c3e52a9cad81b165aa05c0935b1';

/// Takes or picks a progress photo and saves it.

abstract class _$ProgressPhotoCaptureController extends $AsyncNotifier<void> {
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
