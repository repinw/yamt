// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_budget_eaten_view_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the budget card's numbers show what was eaten instead of what is
/// left ("Übrig | Gegessen"). Starts on what is left whenever the diary
/// opens.

@ProviderFor(DiaryBudgetEatenViewController)
final diaryBudgetEatenViewControllerProvider =
    DiaryBudgetEatenViewControllerProvider._();

/// Whether the budget card's numbers show what was eaten instead of what is
/// left ("Übrig | Gegessen"). Starts on what is left whenever the diary
/// opens.
final class DiaryBudgetEatenViewControllerProvider
    extends $NotifierProvider<DiaryBudgetEatenViewController, bool> {
  /// Whether the budget card's numbers show what was eaten instead of what is
  /// left ("Übrig | Gegessen"). Starts on what is left whenever the diary
  /// opens.
  DiaryBudgetEatenViewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBudgetEatenViewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBudgetEatenViewControllerHash();

  @$internal
  @override
  DiaryBudgetEatenViewController create() => DiaryBudgetEatenViewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryBudgetEatenViewControllerHash() =>
    r'2004784fb5a712bd69410a3ff7634429b0fce561';

/// Whether the budget card's numbers show what was eaten instead of what is
/// left ("Übrig | Gegessen"). Starts on what is left whenever the diary
/// opens.

abstract class _$DiaryBudgetEatenViewController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
