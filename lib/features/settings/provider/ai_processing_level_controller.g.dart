// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_processing_level_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AiProcessingLevelController)
final aiProcessingLevelControllerProvider =
    AiProcessingLevelControllerProvider._();

final class AiProcessingLevelControllerProvider
    extends $NotifierProvider<AiProcessingLevelController, AiProcessingLevel> {
  AiProcessingLevelControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiProcessingLevelControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiProcessingLevelControllerHash();

  @$internal
  @override
  AiProcessingLevelController create() => AiProcessingLevelController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiProcessingLevel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiProcessingLevel>(value),
    );
  }
}

String _$aiProcessingLevelControllerHash() =>
    r'85e965d31e8613720e318a91397a0d26713b15f0';

abstract class _$AiProcessingLevelController
    extends $Notifier<AiProcessingLevel> {
  AiProcessingLevel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiProcessingLevel, AiProcessingLevel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiProcessingLevel, AiProcessingLevel>,
              AiProcessingLevel,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
