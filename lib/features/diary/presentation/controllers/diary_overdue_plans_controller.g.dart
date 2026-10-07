// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_overdue_plans_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, or null when there are none
/// or the user closed the hint for them. Closing hides the hint until a
/// later day has overdue plans; the choice is saved on the device.

@ProviderFor(DiaryOverduePlansController)
final diaryOverduePlansControllerProvider =
    DiaryOverduePlansControllerFamily._();

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, or null when there are none
/// or the user closed the hint for them. Closing hides the hint until a
/// later day has overdue plans; the choice is saved on the device.
final class DiaryOverduePlansControllerProvider
    extends $NotifierProvider<DiaryOverduePlansController, List<DateTime>?> {
  /// The days of the last week before [today] that the calendar can open
  /// and whose plans were never eaten or removed, or null when there are none
  /// or the user closed the hint for them. Closing hides the hint until a
  /// later day has overdue plans; the choice is saved on the device.
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
    r'9a00410081e62420d76dda9e1933648b7138bbb7';

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, or null when there are none
/// or the user closed the hint for them. Closing hides the hint until a
/// later day has overdue plans; the choice is saved on the device.

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

  /// The days of the last week before [today] that the calendar can open
  /// and whose plans were never eaten or removed, or null when there are none
  /// or the user closed the hint for them. Closing hides the hint until a
  /// later day has overdue plans; the choice is saved on the device.

  DiaryOverduePlansControllerProvider call(DateTime today) =>
      DiaryOverduePlansControllerProvider._(argument: today, from: this);

  @override
  String toString() => r'diaryOverduePlansControllerProvider';
}

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, or null when there are none
/// or the user closed the hint for them. Closing hides the hint until a
/// later day has overdue plans; the choice is saved on the device.

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
