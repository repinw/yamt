// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase AI Chef repository provider.

@ProviderFor(aiChefRepository)
final aiChefRepositoryProvider = AiChefRepositoryProvider._();

/// Firebase AI Chef repository provider.

final class AiChefRepositoryProvider
    extends
        $FunctionalProvider<
          FirebaseAiChefRepository,
          FirebaseAiChefRepository,
          FirebaseAiChefRepository
        >
    with $Provider<FirebaseAiChefRepository> {
  /// Firebase AI Chef repository provider.
  AiChefRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChefRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChefRepositoryHash();

  @$internal
  @override
  $ProviderElement<FirebaseAiChefRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAiChefRepository create(Ref ref) {
    return aiChefRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAiChefRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAiChefRepository>(value),
    );
  }
}

String _$aiChefRepositoryHash() => r'a628e72c765cacc4525ab68f9ee17bf411936f95';
