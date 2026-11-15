// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_image_generator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The image generator. It depends on nothing that changes, so a picture
/// that is being made is never asked for a second time.

@ProviderFor(aiChefImageGenerator)
final aiChefImageGeneratorProvider = AiChefImageGeneratorProvider._();

/// The image generator. It depends on nothing that changes, so a picture
/// that is being made is never asked for a second time.

final class AiChefImageGeneratorProvider
    extends
        $FunctionalProvider<
          AiChefImageGenerator,
          AiChefImageGenerator,
          AiChefImageGenerator
        >
    with $Provider<AiChefImageGenerator> {
  /// The image generator. It depends on nothing that changes, so a picture
  /// that is being made is never asked for a second time.
  AiChefImageGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChefImageGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChefImageGeneratorHash();

  @$internal
  @override
  $ProviderElement<AiChefImageGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiChefImageGenerator create(Ref ref) {
    return aiChefImageGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChefImageGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChefImageGenerator>(value),
    );
  }
}

String _$aiChefImageGeneratorHash() =>
    r'4756760f1f7ff2be185bb00b23cdaeb6b2c70f90';
