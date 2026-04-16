// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_barcode_backfill_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie barcode backfill repository.

@ProviderFor(calorieBarcodeBackfillRepository)
final calorieBarcodeBackfillRepositoryProvider =
    CalorieBarcodeBackfillRepositoryProvider._();

/// Calorie barcode backfill repository.

final class CalorieBarcodeBackfillRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieBarcodeBackfillRepositoryContract,
          CalorieBarcodeBackfillRepositoryContract,
          CalorieBarcodeBackfillRepositoryContract
        >
    with $Provider<CalorieBarcodeBackfillRepositoryContract> {
  /// Calorie barcode backfill repository.
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
    r'22edfe08f229e8ab50ab452a286756c4beaccf70';
