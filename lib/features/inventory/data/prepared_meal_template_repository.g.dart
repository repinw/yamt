// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_template_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prepared meal template repository.

@ProviderFor(preparedMealTemplateRepository)
final preparedMealTemplateRepositoryProvider =
    PreparedMealTemplateRepositoryProvider._();

/// Prepared meal template repository.

final class PreparedMealTemplateRepositoryProvider
    extends
        $FunctionalProvider<
          PreparedMealTemplateRepository,
          PreparedMealTemplateRepository,
          PreparedMealTemplateRepository
        >
    with $Provider<PreparedMealTemplateRepository> {
  /// Prepared meal template repository.
  PreparedMealTemplateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealTemplateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealTemplateRepositoryHash();

  @$internal
  @override
  $ProviderElement<PreparedMealTemplateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealTemplateRepository create(Ref ref) {
    return preparedMealTemplateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealTemplateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealTemplateRepository>(
        value,
      ),
    );
  }
}

String _$preparedMealTemplateRepositoryHash() =>
    r'1f6e382369c3b50c7214e85050e67a85504a06f7';
