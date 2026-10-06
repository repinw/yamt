// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_after_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the head counts the open plans of today, so it shows what is
/// left after them ("Nach Plan"). On by default; the choice is saved on the
/// device.

@ProviderFor(DiaryAfterPlanController)
final diaryAfterPlanControllerProvider = DiaryAfterPlanControllerProvider._();

/// Whether the head counts the open plans of today, so it shows what is
/// left after them ("Nach Plan"). On by default; the choice is saved on the
/// device.
final class DiaryAfterPlanControllerProvider
    extends $NotifierProvider<DiaryAfterPlanController, bool> {
  /// Whether the head counts the open plans of today, so it shows what is
  /// left after them ("Nach Plan"). On by default; the choice is saved on the
  /// device.
  DiaryAfterPlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryAfterPlanControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryAfterPlanControllerHash();

  @$internal
  @override
  DiaryAfterPlanController create() => DiaryAfterPlanController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryAfterPlanControllerHash() =>
    r'd7c0b06cb8d1dda88c68f61f9199f6c79dbefd92';

/// Whether the head counts the open plans of today, so it shows what is
/// left after them ("Nach Plan"). On by default; the choice is saved on the
/// device.

abstract class _$DiaryAfterPlanController extends $Notifier<bool> {
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

/// The open plans of [day], counted when the user counts them; null when the
/// day offers none.

@ProviderFor(diaryOpenPlans)
final diaryOpenPlansProvider = DiaryOpenPlansFamily._();

/// The open plans of [day], counted when the user counts them; null when the
/// day offers none.

final class DiaryOpenPlansProvider
    extends
        $FunctionalProvider<DiaryOpenPlans?, DiaryOpenPlans?, DiaryOpenPlans?>
    with $Provider<DiaryOpenPlans?> {
  /// The open plans of [day], counted when the user counts them; null when the
  /// day offers none.
  DiaryOpenPlansProvider._({
    required DiaryOpenPlansFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryOpenPlansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryOpenPlansHash();

  @override
  String toString() {
    return r'diaryOpenPlansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DiaryOpenPlans?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiaryOpenPlans? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryOpenPlans(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryOpenPlans? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryOpenPlans?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryOpenPlansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryOpenPlansHash() => r'8f0e95ed9728b01d033acd859ab214403f41ee1e';

/// The open plans of [day], counted when the user counts them; null when the
/// day offers none.

final class DiaryOpenPlansFamily extends $Family
    with $FunctionalFamilyOverride<DiaryOpenPlans?, DateTime> {
  DiaryOpenPlansFamily._()
    : super(
        retry: null,
        name: r'diaryOpenPlansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The open plans of [day], counted when the user counts them; null when the
  /// day offers none.

  DiaryOpenPlansProvider call(DateTime day) =>
      DiaryOpenPlansProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryOpenPlansProvider';
}
