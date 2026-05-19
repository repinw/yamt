// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_cooking_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds cooking instruction steps for the current recipe and inventory.

@ProviderFor(cookingInstructionSteps)
final cookingInstructionStepsProvider = CookingInstructionStepsFamily._();

/// Builds cooking instruction steps for the current recipe and inventory.

final class CookingInstructionStepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CookingFlowInstructionStep>>,
          List<CookingFlowInstructionStep>,
          FutureOr<List<CookingFlowInstructionStep>>
        >
    with
        $FutureModifier<List<CookingFlowInstructionStep>>,
        $FutureProvider<List<CookingFlowInstructionStep>> {
  /// Builds cooking instruction steps for the current recipe and inventory.
  CookingInstructionStepsProvider._({
    required CookingInstructionStepsFamily super.from,
    required CookingInstructionStepsRequest super.argument,
  }) : super(
         retry: null,
         name: r'cookingInstructionStepsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      InventoryItemsControllerProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$cookingInstructionStepsHash();

  @override
  String toString() {
    return r'cookingInstructionStepsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CookingFlowInstructionStep>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CookingFlowInstructionStep>> create(Ref ref) {
    final argument = this.argument as CookingInstructionStepsRequest;
    return cookingInstructionSteps(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CookingInstructionStepsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookingInstructionStepsHash() =>
    r'9102dd2823e4030ea300dcc014f7dd6b58819a01';

/// Builds cooking instruction steps for the current recipe and inventory.

final class CookingInstructionStepsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CookingFlowInstructionStep>>,
          CookingInstructionStepsRequest
        > {
  CookingInstructionStepsFamily._()
    : super(
        retry: null,
        name: r'cookingInstructionStepsProvider',
        dependencies: <ProviderOrFamily>[inventoryItemsControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CookingInstructionStepsProvider.$allTransitiveDependencies0,
          CookingInstructionStepsProvider.$allTransitiveDependencies1,
          CookingInstructionStepsProvider.$allTransitiveDependencies2,
          CookingInstructionStepsProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  /// Builds cooking instruction steps for the current recipe and inventory.

  CookingInstructionStepsProvider call(
    CookingInstructionStepsRequest request,
  ) => CookingInstructionStepsProvider._(argument: request, from: this);

  @override
  String toString() => r'cookingInstructionStepsProvider';
}
