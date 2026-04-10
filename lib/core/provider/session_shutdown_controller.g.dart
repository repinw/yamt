// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_shutdown_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionShutdownController)
final sessionShutdownControllerProvider = SessionShutdownControllerProvider._();

final class SessionShutdownControllerProvider
    extends $NotifierProvider<SessionShutdownController, bool> {
  SessionShutdownControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionShutdownControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionShutdownControllerHash();

  @$internal
  @override
  SessionShutdownController create() => SessionShutdownController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sessionShutdownControllerHash() =>
    r'f5c01ec8170055e8eedf94cbe83d68a0e431fa95';

abstract class _$SessionShutdownController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
