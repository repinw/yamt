// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_cooking_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The service that turns cooked ingredient rows into a Vorrat meal.

@ProviderFor(preparedMealCookingService)
final preparedMealCookingServiceProvider =
    PreparedMealCookingServiceProvider._();

/// The service that turns cooked ingredient rows into a Vorrat meal.

final class PreparedMealCookingServiceProvider
    extends
        $FunctionalProvider<
          PreparedMealCookingService,
          PreparedMealCookingService,
          PreparedMealCookingService
        >
    with $Provider<PreparedMealCookingService> {
  /// The service that turns cooked ingredient rows into a Vorrat meal.
  PreparedMealCookingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealCookingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealCookingServiceHash();

  @$internal
  @override
  $ProviderElement<PreparedMealCookingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealCookingService create(Ref ref) {
    return preparedMealCookingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealCookingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealCookingService>(value),
    );
  }
}

String _$preparedMealCookingServiceHash() =>
    r'f36eb9ed6867441c47935bc0f52277f5330f98b1';
