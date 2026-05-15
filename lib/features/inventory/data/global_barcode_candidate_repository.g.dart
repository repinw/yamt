// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_barcode_candidate_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global barcode candidate repository provider.

@ProviderFor(globalBarcodeCandidateRepository)
final globalBarcodeCandidateRepositoryProvider =
    GlobalBarcodeCandidateRepositoryProvider._();

/// The global barcode candidate repository provider.

final class GlobalBarcodeCandidateRepositoryProvider
    extends
        $FunctionalProvider<
          GlobalBarcodeCandidateRepository,
          GlobalBarcodeCandidateRepository,
          GlobalBarcodeCandidateRepository
        >
    with $Provider<GlobalBarcodeCandidateRepository> {
  /// The global barcode candidate repository provider.
  GlobalBarcodeCandidateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalBarcodeCandidateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalBarcodeCandidateRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlobalBarcodeCandidateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalBarcodeCandidateRepository create(Ref ref) {
    return globalBarcodeCandidateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalBarcodeCandidateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalBarcodeCandidateRepository>(
        value,
      ),
    );
  }
}

String _$globalBarcodeCandidateRepositoryHash() =>
    r'a8b87bd3e4cc576a9c160d39d76adcb944015fc4';
