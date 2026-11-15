// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_link_read_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads recipe pages for the link flow.

@ProviderFor(RecipeLinkReadController)
final recipeLinkReadControllerProvider = RecipeLinkReadControllerProvider._();

/// Reads recipe pages for the link flow.
final class RecipeLinkReadControllerProvider
    extends $AsyncNotifierProvider<RecipeLinkReadController, void> {
  /// Reads recipe pages for the link flow.
  RecipeLinkReadControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeLinkReadControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeLinkReadControllerHash();

  @$internal
  @override
  RecipeLinkReadController create() => RecipeLinkReadController();
}

String _$recipeLinkReadControllerHash() =>
    r'cde50df7b9ef296fec039313b29424745e91665f';

/// Reads recipe pages for the link flow.

abstract class _$RecipeLinkReadController extends $AsyncNotifier<void> {
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
