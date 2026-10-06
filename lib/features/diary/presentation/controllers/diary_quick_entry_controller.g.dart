// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_quick_entry_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the input of the quick entry page and saves it as a calorie entry
/// without a food behind it.

@ProviderFor(DiaryQuickEntryController)
final diaryQuickEntryControllerProvider = DiaryQuickEntryControllerFamily._();

/// Holds the input of the quick entry page and saves it as a calorie entry
/// without a food behind it.
final class DiaryQuickEntryControllerProvider
    extends $NotifierProvider<DiaryQuickEntryController, DiaryQuickEntryState> {
  /// Holds the input of the quick entry page and saves it as a calorie entry
  /// without a food behind it.
  DiaryQuickEntryControllerProvider._({
    required DiaryQuickEntryControllerFamily super.from,
    required ({DateTime initialLoggedAt, MealType initialMealType})
    super.argument,
  }) : super(
         retry: null,
         name: r'diaryQuickEntryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryQuickEntryControllerHash();

  @override
  String toString() {
    return r'diaryQuickEntryControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DiaryQuickEntryController create() => DiaryQuickEntryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryQuickEntryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryQuickEntryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryQuickEntryControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryQuickEntryControllerHash() =>
    r'f72ccb9acea2f3e01052e316d62d561c2eede34c';

/// Holds the input of the quick entry page and saves it as a calorie entry
/// without a food behind it.

final class DiaryQuickEntryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryQuickEntryController,
          DiaryQuickEntryState,
          DiaryQuickEntryState,
          DiaryQuickEntryState,
          ({DateTime initialLoggedAt, MealType initialMealType})
        > {
  DiaryQuickEntryControllerFamily._()
    : super(
        retry: null,
        name: r'diaryQuickEntryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the input of the quick entry page and saves it as a calorie entry
  /// without a food behind it.

  DiaryQuickEntryControllerProvider call({
    required DateTime initialLoggedAt,
    required MealType initialMealType,
  }) => DiaryQuickEntryControllerProvider._(
    argument: (
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    ),
    from: this,
  );

  @override
  String toString() => r'diaryQuickEntryControllerProvider';
}

/// Holds the input of the quick entry page and saves it as a calorie entry
/// without a food behind it.

abstract class _$DiaryQuickEntryController
    extends $Notifier<DiaryQuickEntryState> {
  late final _$args =
      ref.$arg as ({DateTime initialLoggedAt, MealType initialMealType});
  DateTime get initialLoggedAt => _$args.initialLoggedAt;
  MealType get initialMealType => _$args.initialMealType;

  DiaryQuickEntryState build({
    required DateTime initialLoggedAt,
    required MealType initialMealType,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryQuickEntryState, DiaryQuickEntryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryQuickEntryState, DiaryQuickEntryState>,
              DiaryQuickEntryState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        initialLoggedAt: _$args.initialLoggedAt,
        initialMealType: _$args.initialMealType,
      ),
    );
  }
}
