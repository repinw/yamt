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
    r'ab163119feba468478d8e711a3aa4e5b4df7c682';

/// Defines auth form controller.

abstract class _$AuthFormController extends $AsyncNotifier<void> {
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
