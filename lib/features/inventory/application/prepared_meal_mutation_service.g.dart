// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_mutation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one queue of the meal mutations, so they run one after the other
/// also across rebuilds of [preparedMealMutationServiceProvider].

@ProviderFor(preparedMealMutationQueue)
final preparedMealMutationQueueProvider = PreparedMealMutationQueueProvider._();

/// The one queue of the meal mutations, so they run one after the other
/// also across rebuilds of [preparedMealMutationServiceProvider].

final class PreparedMealMutationQueueProvider
    extends
        $FunctionalProvider<
          SerializedMutationQueue,
          SerializedMutationQueue,
          SerializedMutationQueue
        >
    with $Provider<SerializedMutationQueue> {
  /// The one queue of the meal mutations, so they run one after the other
  /// also across rebuilds of [preparedMealMutationServiceProvider].
  PreparedMealMutationQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealMutationQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealMutationQueueHash();

  @$internal
  @override
  $ProviderElement<SerializedMutationQueue> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SerializedMutationQueue create(Ref ref) {
    return preparedMealMutationQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SerializedMutationQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SerializedMutationQueue>(value),
    );
  }
}

String _$preparedMealMutationQueueHash() =>
    r'74ae03cc5e19548a0d26cbcc3e6b3bce5dc4f0c4';

/// The prepared meal mutations provider.

@ProviderFor(preparedMealMutationService)
final preparedMealMutationServiceProvider =
    PreparedMealMutationServiceProvider._();

/// The prepared meal mutations provider.

final class PreparedMealMutationServiceProvider
    extends
        $FunctionalProvider<
          PreparedMealMutationService,
          PreparedMealMutationService,
          PreparedMealMutationService
        >
    with $Provider<PreparedMealMutationService> {
  /// The prepared meal mutations provider.
  PreparedMealMutationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealMutationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealMutationServiceHash();

  @$internal
  @override
  $ProviderElement<PreparedMealMutationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealMutationService create(Ref ref) {
    return preparedMealMutationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealMutationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealMutationService>(value),
    );
  }
}

String _$preparedMealMutationServiceHash() =>
    r'8cd7438929529f801dcdb769b16fb46bf60eda86';
