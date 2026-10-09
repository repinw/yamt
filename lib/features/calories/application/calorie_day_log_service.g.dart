// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_day_log_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The calorie day log service.

@ProviderFor(calorieDayLogService)
final calorieDayLogServiceProvider = CalorieDayLogServiceProvider._();

/// The calorie day log service.

final class CalorieDayLogServiceProvider
    extends
        $FunctionalProvider<
          CalorieDayLogService,
          CalorieDayLogService,
          CalorieDayLogService
        >
    with $Provider<CalorieDayLogService> {
  /// The calorie day log service.
  CalorieDayLogServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieDayLogServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieDayLogServiceHash();

  @$internal
  @override
  $ProviderElement<CalorieDayLogService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieDayLogService create(Ref ref) {
    return calorieDayLogService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieDayLogService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieDayLogService>(value),
    );
  }
}

String _$calorieDayLogServiceHash() =>
    r'2b24303cb494a3ff5d31bef814e66d7624979577';
