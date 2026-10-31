// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_overdue_plans_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, oldest first; empty when
/// there are none.

@ProviderFor(diaryOverduePlanDays)
final diaryOverduePlanDaysProvider = DiaryOverduePlanDaysFamily._();

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, oldest first; empty when
/// there are none.

final class DiaryOverduePlanDaysProvider
    extends $FunctionalProvider<List<DateTime>, List<DateTime>, List<DateTime>>
    with $Provider<List<DateTime>> {
  /// The days of the last week before [today] that the calendar can open
  /// and whose plans were never eaten or removed, oldest first; empty when
  /// there are none.
  DiaryOverduePlanDaysProvider._({
    required DiaryOverduePlanDaysFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryOverduePlanDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryOverduePlanDaysHash();

  @override
  String toString() {
    return r'diaryOverduePlanDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<DateTime>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<DateTime> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryOverduePlanDays(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DateTime> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DateTime>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryOverduePlanDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryOverduePlanDaysHash() =>
    r'5e662edacb16c3d78331df2492cdddfaa3c6f2d3';

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, oldest first; empty when
/// there are none.

final class DiaryOverduePlanDaysFamily extends $Family
    with $FunctionalFamilyOverride<List<DateTime>, DateTime> {
  DiaryOverduePlanDaysFamily._()
    : super(
        retry: null,
        name: r'diaryOverduePlanDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The days of the last week before [today] that the calendar can open
  /// and whose plans were never eaten or removed, oldest first; empty when
  /// there are none.

  DiaryOverduePlanDaysProvider call(DateTime today) =>
      DiaryOverduePlanDaysProvider._(argument: today, from: this);

  @override
  String toString() => r'diaryOverduePlanDaysProvider';
}

/// The [diaryOverduePlanDays] of [today] for the hint, or null when there
/// are none or the user closed the hint for them. Closing hides the hint
/// until a later day has overdue plans; the choice is saved on the device.

@ProviderFor(DiaryOverduePlansController)
final diaryOverduePlansControllerProvider =
    DiaryOverduePlansControllerFamily._();

/// The [diaryOverduePlanDays] of [today] for the hint, or null when there
/// are none or the user closed the hint for them. Closing hides the hint
/// until a later day has overdue plans; the choice is saved on the device.
final class DiaryOverduePlansControllerProvider
    extends $NotifierProvider<DiaryOverduePlansController, List<DateTime>?> {
  /// The [diaryOverduePlanDays] of [today] for the hint, or null when there
  /// are none or the user closed the hint for them. Closing hides the hint
  /// until a later day has overdue plans; the choice is saved on the device.
  DiaryOverduePlansControllerProvider._({
    required DiaryOverduePlansControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryOverduePlansControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryOverduePlansControllerHash();

  @override
  String toString() {
    return r'diaryOverduePlansControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DiaryOverduePlansController create() => DiaryOverduePlansController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DateTime>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DateTime>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryOverduePlansControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryOverduePlansControllerHash() =>
    r'9212bdab2f79a50cf24870b08a7e91c845358df3';

/// The [diaryOverduePlanDays] of [today] for the hint, or null when there
/// are none or the user closed the hint for them. Closing hides the hint
/// until a later day has overdue plans; the choice is saved on the device.

final class DiaryOverduePlansControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DiaryOverduePlansController,
          List<DateTime>?,
          List<DateTime>?,
          List<DateTime>?,
          DateTime
        > {
  DiaryOverduePlansControllerFamily._()
    : super(
        retry: null,
        name: r'diaryOverduePlansControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The [diaryOverduePlanDays] of [today] for the hint, or null when there
  /// are none or the user closed the hint for them. Closing hides the hint
  /// until a later day has overdue plans; the choice is saved on the device.

  DiaryOverduePlansControllerProvider call(DateTime today) =>
      DiaryOverduePlansControllerProvider._(argument: today, from: this);

  @override
  String toString() => r'diaryOverduePlansControllerProvider';
}

/// The [diaryOverduePlanDays] of [today] for the hint, or null when there
/// are none or the user closed the hint for them. Closing hides the hint
/// until a later day has overdue plans; the choice is saved on the device.

abstract class _$DiaryOverduePlansController
    extends $Notifier<List<DateTime>?> {
  late final _$args = ref.$arg as DateTime;
  DateTime get today => _$args;

  List<DateTime>? build(DateTime today);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DateTime>?, List<DateTime>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DateTime>?, List<DateTime>?>,
              List<DateTime>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
