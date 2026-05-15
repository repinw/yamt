// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weight_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Weight actions used by diary weight widgets.

@ProviderFor(diaryWeightActions)
final diaryWeightActionsProvider = DiaryWeightActionsProvider._();

/// Weight actions used by diary weight widgets.

final class DiaryWeightActionsProvider
    extends
        $FunctionalProvider<
          DiaryWeightActions,
          DiaryWeightActions,
          DiaryWeightActions
        >
    with $Provider<DiaryWeightActions> {
  /// Weight actions used by diary weight widgets.
  DiaryWeightActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeightActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeightActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryWeightActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryWeightActions create(Ref ref) {
    return diaryWeightActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryWeightActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryWeightActions>(value),
    );
  }
}

String _$diaryWeightActionsHash() =>
    r'2f74101b74dfed02c9bfeccaee6d6b95ffcc4389';
