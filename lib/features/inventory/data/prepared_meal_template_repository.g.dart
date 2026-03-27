// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_template_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(preparedMealTemplateRepository)
final preparedMealTemplateRepositoryProvider =
    PreparedMealTemplateRepositoryProvider._();

final class PreparedMealTemplateRepositoryProvider
    extends
        $FunctionalProvider<
          PreparedMealTemplateRepository,
          PreparedMealTemplateRepository,
          PreparedMealTemplateRepository
        >
    with $Provider<PreparedMealTemplateRepository> {
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
    r'ddc4464b717811c52d51dc74190a6d108c21b2aa';
