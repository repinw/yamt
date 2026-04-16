// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_health_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Diary health service.

@ProviderFor(diaryHealthService)
final diaryHealthServiceProvider = DiaryHealthServiceProvider._();

/// Diary health service.

final class DiaryHealthServiceProvider
    extends
        $FunctionalProvider<
          DiaryHealthService,
          DiaryHealthService,
          DiaryHealthService
        >
    with $Provider<DiaryHealthService> {
  /// Diary health service.
  DiaryHealthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryHealthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryHealthServiceHash();

  @$internal
  @override
  $ProviderElement<DiaryHealthService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryHealthService create(Ref ref) {
    return diaryHealthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryHealthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryHealthService>(value),
    );
  }
}

String _$diaryHealthServiceHash() =>
    r'c22506f45136d837552afedce894252702f25df9';
