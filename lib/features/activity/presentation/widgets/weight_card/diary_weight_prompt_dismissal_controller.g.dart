// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weight_prompt_dismissal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stores the last diary day where the user dismissed the weight prompt.

@ProviderFor(DiaryWeightPromptDismissalController)
final diaryWeightPromptDismissalControllerProvider =
    DiaryWeightPromptDismissalControllerProvider._();

/// Stores the last diary day where the user dismissed the weight prompt.
final class DiaryWeightPromptDismissalControllerProvider
    extends $NotifierProvider<DiaryWeightPromptDismissalController, String?> {
  /// Stores the last diary day where the user dismissed the weight prompt.
  DiaryWeightPromptDismissalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeightPromptDismissalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryWeightPromptDismissalControllerHash();

  @$internal
  @override
  DiaryWeightPromptDismissalController create() =>
      DiaryWeightPromptDismissalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$diaryWeightPromptDismissalControllerHash() =>
    r'bdc8384357e8c69517cd8763de1acad40a5ffa97';

/// Stores the last diary day where the user dismissed the weight prompt.

abstract class _$DiaryWeightPromptDismissalController
    extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
