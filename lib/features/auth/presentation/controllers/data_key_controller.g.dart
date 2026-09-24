// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_key_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs the actions of the data key pages.

@ProviderFor(DataKeyController)
final dataKeyControllerProvider = DataKeyControllerProvider._();

/// Runs the actions of the data key pages.
final class DataKeyControllerProvider
    extends $AsyncNotifierProvider<DataKeyController, void> {
  /// Runs the actions of the data key pages.
  DataKeyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataKeyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataKeyControllerHash();

  @$internal
  @override
  DataKeyController create() => DataKeyController();
}

String _$dataKeyControllerHash() => r'd2727df31e18d19ba3f7dcab6efb2f79a9459ce2';

/// Runs the actions of the data key pages.

abstract class _$DataKeyController extends $AsyncNotifier<void> {
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
