// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_combine_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Foods picked on the item hub of [hubItemId] to log together with it.
///
/// The hub item's own request decides day and meal; a pick's `loggedAt` and
/// `mealType` are placeholders.

@ProviderFor(InventoryItemCombineController)
final inventoryItemCombineControllerProvider =
    InventoryItemCombineControllerFamily._();

/// Foods picked on the item hub of [hubItemId] to log together with it.
///
/// The hub item's own request decides day and meal; a pick's `loggedAt` and
/// `mealType` are placeholders.
final class InventoryItemCombineControllerProvider
    extends
        $NotifierProvider<
          InventoryItemCombineController,
          List<InventoryCombinePick>
        > {
  /// Foods picked on the item hub of [hubItemId] to log together with it.
  ///
  /// The hub item's own request decides day and meal; a pick's `loggedAt` and
  /// `mealType` are placeholders.
  InventoryItemCombineControllerProvider._({
    required InventoryItemCombineControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inventoryItemCombineControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemCombineControllerHash();

  @override
  String toString() {
    return r'inventoryItemCombineControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InventoryItemCombineController create() => InventoryItemCombineController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InventoryCombinePick> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InventoryCombinePick>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryItemCombineControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryItemCombineControllerHash() =>
    r'8e147fe16c59a5665e0d9469d99b817511299935';

/// Foods picked on the item hub of [hubItemId] to log together with it.
///
/// The hub item's own request decides day and meal; a pick's `loggedAt` and
/// `mealType` are placeholders.

final class InventoryItemCombineControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          InventoryItemCombineController,
          List<InventoryCombinePick>,
          List<InventoryCombinePick>,
          List<InventoryCombinePick>,
          String
        > {
  InventoryItemCombineControllerFamily._()
    : super(
        retry: null,
        name: r'inventoryItemCombineControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Foods picked on the item hub of [hubItemId] to log together with it.
  ///
  /// The hub item's own request decides day and meal; a pick's `loggedAt` and
  /// `mealType` are placeholders.

  InventoryItemCombineControllerProvider call(String hubItemId) =>
      InventoryItemCombineControllerProvider._(argument: hubItemId, from: this);

  @override
  String toString() => r'inventoryItemCombineControllerProvider';
}

/// Foods picked on the item hub of [hubItemId] to log together with it.
///
/// The hub item's own request decides day and meal; a pick's `loggedAt` and
/// `mealType` are placeholders.

abstract class _$InventoryItemCombineController
    extends $Notifier<List<InventoryCombinePick>> {
  late final _$args = ref.$arg as String;
  String get hubItemId => _$args;

  List<InventoryCombinePick> build(String hubItemId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<InventoryCombinePick>, List<InventoryCombinePick>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<InventoryCombinePick>,
                List<InventoryCombinePick>
              >,
              List<InventoryCombinePick>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
