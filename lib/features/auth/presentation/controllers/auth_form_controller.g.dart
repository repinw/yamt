// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines auth form controller.

@ProviderFor(AuthFormController)
final authFormControllerProvider = AuthFormControllerProvider._();

/// Defines auth form controller.
final class AuthFormControllerProvider
    extends $AsyncNotifierProvider<AuthFormController, void> {
  /// Defines auth form controller.
  AuthFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authFormControllerHash();

  @$internal
  @override
  AuthFormController create() => AuthFormController();
}

String _$authFormControllerHash() =>
    r'4f1533a466f5eaa5576e84ca24a57fc078ebb90a';

/// Defines auth form controller.

abstract class _$AuthFormController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
