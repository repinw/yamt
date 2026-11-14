// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Steps through a list import: null while the user gives the list, then
/// the read, then the review of what was read.

@ProviderFor(ShoppingImportController)
final shoppingImportControllerProvider = ShoppingImportControllerProvider._();

/// Steps through a list import: null while the user gives the list, then
/// the read, then the review of what was read.
final class ShoppingImportControllerProvider
    extends
        $NotifierProvider<
          ShoppingImportController,
          AsyncValue<ShoppingImportReview>?
        > {
  /// Steps through a list import: null while the user gives the list, then
  /// the read, then the review of what was read.
  ShoppingImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingImportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingImportControllerHash();

  @$internal
  @override
  ShoppingImportController create() => ShoppingImportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ShoppingImportReview>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ShoppingImportReview>?>(
        value,
      ),
    );
  }
}

String _$shoppingImportControllerHash() =>
    r'1b6dff8afc35bbf2a930f598e1aec4c2cd406f7e';

/// Steps through a list import: null while the user gives the list, then
/// the read, then the review of what was read.

abstract class _$ShoppingImportController
    extends $Notifier<AsyncValue<ShoppingImportReview>?> {
  AsyncValue<ShoppingImportReview>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ShoppingImportReview>?,
              AsyncValue<ShoppingImportReview>?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ShoppingImportReview>?,
                AsyncValue<ShoppingImportReview>?
              >,
              AsyncValue<ShoppingImportReview>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
