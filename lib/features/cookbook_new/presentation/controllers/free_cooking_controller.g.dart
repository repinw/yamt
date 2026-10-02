// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_cooking_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the rows of a meal cooked without a recipe and saves it as a Vorrat
/// meal.

@ProviderFor(FreeCookingController)
final freeCookingControllerProvider = FreeCookingControllerProvider._();

/// Holds the rows of a meal cooked without a recipe and saves it as a Vorrat
/// meal.
final class FreeCookingControllerProvider
    extends $NotifierProvider<FreeCookingController, FreeCookingDraft> {
  /// Holds the rows of a meal cooked without a recipe and saves it as a Vorrat
  /// meal.
  FreeCookingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'freeCookingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$freeCookingControllerHash();

  @$internal
  @override
  FreeCookingController create() => FreeCookingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FreeCookingDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FreeCookingDraft>(value),
    );
  }
}

String _$freeCookingControllerHash() =>
    r'78de570212aa09c532f5a74ce6b905f0a1a377be';

/// Holds the rows of a meal cooked without a recipe and saves it as a Vorrat
/// meal.

abstract class _$FreeCookingController extends $Notifier<FreeCookingDraft> {
  FreeCookingDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FreeCookingDraft, FreeCookingDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FreeCookingDraft, FreeCookingDraft>,
              FreeCookingDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The draft rows with their amount and the Vorrat item that supplies each.
/// It loads and fails with the Vorrat.
///
/// It is synchronous, so a removed row is gone in the same frame. A row gets
/// a Vorrat item only when it has an amount in a unit that the item can
/// supply, because only then does "Kochen" take the row from the Vorrat.

@ProviderFor(freeCookingRows)
final freeCookingRowsProvider = FreeCookingRowsFamily._();

/// The draft rows with their amount and the Vorrat item that supplies each.
/// It loads and fails with the Vorrat.
///
/// It is synchronous, so a removed row is gone in the same frame. A row gets
/// a Vorrat item only when it has an amount in a unit that the item can
/// supply, because only then does "Kochen" take the row from the Vorrat.

final class FreeCookingRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FreeCookingRow>>,
          AsyncValue<List<FreeCookingRow>>,
          AsyncValue<List<FreeCookingRow>>
        >
    with $Provider<AsyncValue<List<FreeCookingRow>>> {
  /// The draft rows with their amount and the Vorrat item that supplies each.
  /// It loads and fails with the Vorrat.
  ///
  /// It is synchronous, so a removed row is gone in the same frame. A row gets
  /// a Vorrat item only when it has an amount in a unit that the item can
  /// supply, because only then does "Kochen" take the row from the Vorrat.
  FreeCookingRowsProvider._({
    required FreeCookingRowsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'freeCookingRowsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$freeCookingRowsHash();

  @override
  String toString() {
    return r'freeCookingRowsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<FreeCookingRow>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<FreeCookingRow>> create(Ref ref) {
    final argument = this.argument as String;
    return freeCookingRows(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<FreeCookingRow>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<FreeCookingRow>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FreeCookingRowsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$freeCookingRowsHash() => r'86867272cfda45bdac1c4d3a0b4174a9035df8e6';

/// The draft rows with their amount and the Vorrat item that supplies each.
/// It loads and fails with the Vorrat.
///
/// It is synchronous, so a removed row is gone in the same frame. A row gets
/// a Vorrat item only when it has an amount in a unit that the item can
/// supply, because only then does "Kochen" take the row from the Vorrat.

final class FreeCookingRowsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<FreeCookingRow>>, String> {
  FreeCookingRowsFamily._()
    : super(
        retry: null,
        name: r'freeCookingRowsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The draft rows with their amount and the Vorrat item that supplies each.
  /// It loads and fails with the Vorrat.
  ///
  /// It is synchronous, so a removed row is gone in the same frame. A row gets
  /// a Vorrat item only when it has an amount in a unit that the item can
  /// supply, because only then does "Kochen" take the row from the Vorrat.

  FreeCookingRowsProvider call(String localeCode) =>
      FreeCookingRowsProvider._(argument: localeCode, from: this);

  @override
  String toString() => r'freeCookingRowsProvider';
}
