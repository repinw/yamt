// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthFormController)
final authFormControllerProvider = AuthFormControllerProvider._();

final class AuthFormControllerProvider
    extends $AsyncNotifierProvider<AuthFormController, void> {
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
    r'd1f7ed6e0927cb18a3340b8b5d07c1bf9ac40f2f';

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
