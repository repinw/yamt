// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_eat_sheet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the input of the eat sheet for one inventory item.

@ProviderFor(InventoryItemEatSheetController)
final inventoryItemEatSheetControllerProvider =
    InventoryItemEatSheetControllerFamily._();

/// Holds the input of the eat sheet for one inventory item.
final class InventoryItemEatSheetControllerProvider
    extends
        $NotifierProvider<
          InventoryItemEatSheetController,
          InventoryItemEatSheetState
        > {
  /// Holds the input of the eat sheet for one inventory item.
  InventoryItemEatSheetControllerProvider._({
    required InventoryItemEatSheetControllerFamily super.from,
    required ({
      InventoryItem item,
      int? initialInventoryAmount,
      DateTime? initialLoggedAt,
      MealType? initialMealType,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'inventoryItemEatSheetControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemEatSheetControllerHash();

  @override
  String toString() {
    return r'inventoryItemEatSheetControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  InventoryItemEatSheetController create() => InventoryItemEatSheetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemEatSheetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemEatSheetState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryItemEatSheetControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryItemEatSheetControllerHash() =>
    r'a506c8b44e7bd0d88f3c7936aaa7870fa62c4de6';

/// Holds the input of the eat sheet for one inventory item.

final class InventoryItemEatSheetControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          InventoryItemEatSheetController,
          InventoryItemEatSheetState,
          InventoryItemEatSheetState,
          InventoryItemEatSheetState,
          ({
            InventoryItem item,
            int? initialInventoryAmount,
            DateTime? initialLoggedAt,
            MealType? initialMealType,
          })
        > {
  InventoryItemEatSheetControllerFamily._()
    : super(
        retry: null,
        name: r'inventoryItemEatSheetControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the input of the eat sheet for one inventory item.

  InventoryItemEatSheetControllerProvider call({
    required InventoryItem item,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) => InventoryItemEatSheetControllerProvider._(
    argument: (
      item: item,
      initialInventoryAmount: initialInventoryAmount,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    ),
    from: this,
  );

  @override
  String toString() => r'inventoryItemEatSheetControllerProvider';
}

/// Holds the input of the eat sheet for one inventory item.

abstract class _$InventoryItemEatSheetController
    extends $Notifier<InventoryItemEatSheetState> {
  late final _$args =
      ref.$arg
          as ({
            InventoryItem item,
            int? initialInventoryAmount,
            DateTime? initialLoggedAt,
            MealType? initialMealType,
          });
  InventoryItem get item => _$args.item;
  int? get initialInventoryAmount => _$args.initialInventoryAmount;
  DateTime? get initialLoggedAt => _$args.initialLoggedAt;
  MealType? get initialMealType => _$args.initialMealType;

  InventoryItemEatSheetState build({
    required InventoryItem item,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<InventoryItemEatSheetState, InventoryItemEatSheetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                InventoryItemEatSheetState,
                InventoryItemEatSheetState
              >,
              InventoryItemEatSheetState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        item: _$args.item,
        initialInventoryAmount: _$args.initialInventoryAmount,
        initialLoggedAt: _$args.initialLoggedAt,
        initialMealType: _$args.initialMealType,
      ),
    );
  }
}
