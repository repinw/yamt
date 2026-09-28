// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_utensil_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the saved kitchen utensils, newest first.

@ProviderFor(kitchenUtensilList)
final kitchenUtensilListProvider = KitchenUtensilListProvider._();

/// Watches the saved kitchen utensils, newest first.

final class KitchenUtensilListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KitchenUtensil>>,
          List<KitchenUtensil>,
          Stream<List<KitchenUtensil>>
        >
    with
        $FutureModifier<List<KitchenUtensil>>,
        $StreamProvider<List<KitchenUtensil>> {
  /// Watches the saved kitchen utensils, newest first.
  KitchenUtensilListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenUtensilListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenUtensilListHash();

  @$internal
  @override
  $StreamProviderElement<List<KitchenUtensil>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<KitchenUtensil>> create(Ref ref) {
    return kitchenUtensilList(ref);
  }
}

String _$kitchenUtensilListHash() =>
    r'cab2ea9557fdef212d8c2b873abd5551913a2eb6';
