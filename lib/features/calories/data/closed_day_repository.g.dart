// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'closed_day_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Closed day repository of the signed-in user.

@ProviderFor(closedDayRepository)
final closedDayRepositoryProvider = ClosedDayRepositoryProvider._();

/// Closed day repository of the signed-in user.

final class ClosedDayRepositoryProvider
    extends
        $FunctionalProvider<
          ClosedDayRepository,
          ClosedDayRepository,
          ClosedDayRepository
        >
    with $Provider<ClosedDayRepository> {
  /// Closed day repository of the signed-in user.
  ClosedDayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'closedDayRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$closedDayRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClosedDayRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClosedDayRepository create(Ref ref) {
    return closedDayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClosedDayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClosedDayRepository>(value),
    );
  }
}

String _$closedDayRepositoryHash() =>
    r'cb6fcd4afda2160a21c1fe7519d689aa3ff726db';
