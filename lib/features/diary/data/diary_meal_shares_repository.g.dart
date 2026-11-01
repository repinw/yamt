// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_shares_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the meal shares repository.

@ProviderFor(diaryMealSharesRepository)
final diaryMealSharesRepositoryProvider = DiaryMealSharesRepositoryProvider._();

/// Provides the meal shares repository.

final class DiaryMealSharesRepositoryProvider
    extends
        $FunctionalProvider<
          DiaryMealSharesRepository,
          DiaryMealSharesRepository,
          DiaryMealSharesRepository
        >
    with $Provider<DiaryMealSharesRepository> {
  /// Provides the meal shares repository.
  DiaryMealSharesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryMealSharesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryMealSharesRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiaryMealSharesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryMealSharesRepository create(Ref ref) {
    return diaryMealSharesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryMealSharesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryMealSharesRepository>(value),
    );
  }
}

String _$diaryMealSharesRepositoryHash() =>
    r'dbdf4e2b6e9a6bef9fbf0b5f7e0b92c79d6f2f4f';
