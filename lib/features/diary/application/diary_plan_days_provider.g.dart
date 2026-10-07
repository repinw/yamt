// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_days_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The days within [bounds] that hold open plans, for the calendar dots.
///
/// Accepting a plan deletes it, so every plan read here is still open.

@ProviderFor(diaryPlanDays)
final diaryPlanDaysProvider = DiaryPlanDaysFamily._();

/// The days within [bounds] that hold open plans, for the calendar dots.
///
/// Accepting a plan deletes it, so every plan read here is still open.

final class DiaryPlanDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<DateTime>>,
          Set<DateTime>,
          FutureOr<Set<DateTime>>
        >
    with $FutureModifier<Set<DateTime>>, $FutureProvider<Set<DateTime>> {
  /// The days within [bounds] that hold open plans, for the calendar dots.
  ///
  /// Accepting a plan deletes it, so every plan read here is still open.
  DiaryPlanDaysProvider._({
    required DiaryPlanDaysFamily super.from,
    required DiaryCalendarBounds super.argument,
  }) : super(
         retry: null,
         name: r'diaryPlanDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanDaysHash();

  @override
  String toString() {
    return r'diaryPlanDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Set<DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<DateTime>> create(Ref ref) {
    final argument = this.argument as DiaryCalendarBounds;
    return diaryPlanDays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPlanDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPlanDaysHash() => r'1c41a1dd461585a1704b039dc76346df819e741b';

/// The days within [bounds] that hold open plans, for the calendar dots.
///
/// Accepting a plan deletes it, so every plan read here is still open.

final class DiaryPlanDaysFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Set<DateTime>>,
          DiaryCalendarBounds
        > {
  DiaryPlanDaysFamily._()
    : super(
        retry: null,
        name: r'diaryPlanDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The days within [bounds] that hold open plans, for the calendar dots.
  ///
  /// Accepting a plan deletes it, so every plan read here is still open.

  DiaryPlanDaysProvider call(DiaryCalendarBounds bounds) =>
      DiaryPlanDaysProvider._(argument: bounds, from: this);

  @override
  String toString() => r'diaryPlanDaysProvider';
}
