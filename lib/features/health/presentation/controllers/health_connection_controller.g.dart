// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_connection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines health connection controller.

@ProviderFor(HealthConnectionController)
final healthConnectionControllerProvider =
    HealthConnectionControllerProvider._();

/// Defines health connection controller.
final class HealthConnectionControllerProvider
    extends
        $AsyncNotifierProvider<
          HealthConnectionController,
          HealthConnectionStatus
        > {
  /// Defines health connection controller.
  HealthConnectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectionControllerHash();

  @$internal
  @override
  HealthConnectionController create() => HealthConnectionController();
}

String _$healthConnectionControllerHash() =>
    r'a52078c78b3af05110448140ad63ce3e72fcd6d5';

/// Defines health connection controller.

abstract class _$HealthConnectionController
    extends $AsyncNotifier<HealthConnectionStatus> {
  FutureOr<HealthConnectionStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<HealthConnectionStatus>, HealthConnectionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<HealthConnectionStatus>,
                HealthConnectionStatus
              >,
              AsyncValue<HealthConnectionStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
