// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_exclusions_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AI Chef exclusions repository provider.

@ProviderFor(aiChefExclusionsRepository)
final aiChefExclusionsRepositoryProvider =
    AiChefExclusionsRepositoryProvider._();

/// AI Chef exclusions repository provider.

final class AiChefExclusionsRepositoryProvider
    extends
        $FunctionalProvider<
          AiChefExclusionsRepository,
          AiChefExclusionsRepository,
          AiChefExclusionsRepository
        >
    with $Provider<AiChefExclusionsRepository> {
  /// AI Chef exclusions repository provider.
  AiChefExclusionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChefExclusionsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChefExclusionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiChefExclusionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiChefExclusionsRepository create(Ref ref) {
    return aiChefExclusionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChefExclusionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChefExclusionsRepository>(value),
    );
  }
}

String _$aiChefExclusionsRepositoryHash() =>
    r'cab047a1f5a0d4e79cab564a52232e6edfcdef0f';
