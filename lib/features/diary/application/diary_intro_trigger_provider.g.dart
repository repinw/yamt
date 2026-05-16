// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_intro_trigger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Emits data for the first-week diary intro when it should auto-open.

@ProviderFor(diaryIntroTrigger)
final diaryIntroTriggerProvider = DiaryIntroTriggerProvider._();

/// Emits data for the first-week diary intro when it should auto-open.

final class DiaryIntroTriggerProvider
    extends
        $FunctionalProvider<
          DiaryIntroTrigger?,
          DiaryIntroTrigger?,
          DiaryIntroTrigger?
        >
    with $Provider<DiaryIntroTrigger?> {
  /// Emits data for the first-week diary intro when it should auto-open.
  DiaryIntroTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryIntroTriggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryIntroTriggerHash();

  @$internal
  @override
  $ProviderElement<DiaryIntroTrigger?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryIntroTrigger? create(Ref ref) {
    return diaryIntroTrigger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryIntroTrigger? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryIntroTrigger?>(value),
    );
  }
}

String _$diaryIntroTriggerHash() => r'd21baaacd8616f0c969acb50fc50aac374b604f9';
