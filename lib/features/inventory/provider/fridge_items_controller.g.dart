// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_items_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FridgeItemsController)
final fridgeItemsControllerProvider = FridgeItemsControllerProvider._();

final class FridgeItemsControllerProvider
    extends $AsyncNotifierProvider<FridgeItemsController, List<FridgeItem>> {
  FridgeItemsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fridgeItemsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fridgeItemsControllerHash();

  @$internal
  @override
  FridgeItemsController create() => FridgeItemsController();
}

String _$fridgeItemsControllerHash() =>
    r'edbe68e694928b8d5d6987a30a791b8f1c2fdd5f';

abstract class _$FridgeItemsController
    extends $AsyncNotifier<List<FridgeItem>> {
  FutureOr<List<FridgeItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FridgeItem>>, List<FridgeItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FridgeItem>>, List<FridgeItem>>,
              AsyncValue<List<FridgeItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
