// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_new_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [WhatsNewRepository].

@ProviderFor(whatsNewRepository)
final whatsNewRepositoryProvider = WhatsNewRepositoryProvider._();

/// Provides the [WhatsNewRepository].

final class WhatsNewRepositoryProvider
    extends
        $FunctionalProvider<
          WhatsNewRepository,
          WhatsNewRepository,
          WhatsNewRepository
        >
    with $Provider<WhatsNewRepository> {
  /// Provides the [WhatsNewRepository].
  WhatsNewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whatsNewRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whatsNewRepositoryHash();

  @$internal
  @override
  $ProviderElement<WhatsNewRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WhatsNewRepository create(Ref ref) {
    return whatsNewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WhatsNewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WhatsNewRepository>(value),
    );
  }
}

String _$whatsNewRepositoryHash() =>
    r'05a5c8d5acd1184d960ce1bff8b59b9a03abb6fe';
