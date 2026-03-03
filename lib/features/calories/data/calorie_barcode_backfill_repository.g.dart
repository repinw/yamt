// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_barcode_backfill_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieBarcodeBackfillRepository)
final calorieBarcodeBackfillRepositoryProvider =
    CalorieBarcodeBackfillRepositoryProvider._();

final class CalorieBarcodeBackfillRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieBarcodeBackfillRepositoryContract,
          CalorieBarcodeBackfillRepositoryContract,
          CalorieBarcodeBackfillRepositoryContract
        >
    with $Provider<CalorieBarcodeBackfillRepositoryContract> {
  CalorieBarcodeBackfillRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBarcodeBackfillRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBarcodeBackfillRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieBarcodeBackfillRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieBarcodeBackfillRepositoryContract create(Ref ref) {
    return calorieBarcodeBackfillRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieBarcodeBackfillRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CalorieBarcodeBackfillRepositoryContract>(value),
    );
  }
}

String _$calorieBarcodeBackfillRepositoryHash() =>
    r'e663f85d053e7fefa9ea3752e9284aa341d81c92';
