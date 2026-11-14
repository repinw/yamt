// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_steps_goal_raise.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The goal that the week starting at [weekStart] offers to move up to, or
/// null without an offer. A week offers [healthStepsGoalRaise] more once the
/// week before it met the goal on average, a day without steps counting as
/// zero, until the user answers. A goal set or changed in the running week
/// asks nothing in that week. From the week after, the whole week before
/// is measured against the goal as it stands now, also the days before it
/// was set: its steps either reach the new goal on average or they do not.

@ProviderFor(healthStepsGoalRaiseOffer)
final healthStepsGoalRaiseOfferProvider = HealthStepsGoalRaiseOfferFamily._();

/// The goal that the week starting at [weekStart] offers to move up to, or
/// null without an offer. A week offers [healthStepsGoalRaise] more once the
/// week before it met the goal on average, a day without steps counting as
/// zero, until the user answers. A goal set or changed in the running week
/// asks nothing in that week. From the week after, the whole week before
/// is measured against the goal as it stands now, also the days before it
/// was set: its steps either reach the new goal on average or they do not.

final class HealthStepsGoalRaiseOfferProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// The goal that the week starting at [weekStart] offers to move up to, or
  /// null without an offer. A week offers [healthStepsGoalRaise] more once the
  /// week before it met the goal on average, a day without steps counting as
  /// zero, until the user answers. A goal set or changed in the running week
  /// asks nothing in that week. From the week after, the whole week before
  /// is measured against the goal as it stands now, also the days before it
  /// was set: its steps either reach the new goal on average or they do not.
  HealthStepsGoalRaiseOfferProvider._({
    required HealthStepsGoalRaiseOfferFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'healthStepsGoalRaiseOfferProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$healthStepsGoalRaiseOfferHash();

  @override
  String toString() {
    return r'healthStepsGoalRaiseOfferProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return healthStepsGoalRaiseOffer(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthStepsGoalRaiseOfferProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$healthStepsGoalRaiseOfferHash() =>
    r'25027fbcc63ae9527ece87f256942958e3113a9b';

/// The goal that the week starting at [weekStart] offers to move up to, or
/// null without an offer. A week offers [healthStepsGoalRaise] more once the
/// week before it met the goal on average, a day without steps counting as
/// zero, until the user answers. A goal set or changed in the running week
/// asks nothing in that week. From the week after, the whole week before
/// is measured against the goal as it stands now, also the days before it
/// was set: its steps either reach the new goal on average or they do not.

final class HealthStepsGoalRaiseOfferFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, DateTime> {
  HealthStepsGoalRaiseOfferFamily._()
    : super(
        retry: null,
        name: r'healthStepsGoalRaiseOfferProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The goal that the week starting at [weekStart] offers to move up to, or
  /// null without an offer. A week offers [healthStepsGoalRaise] more once the
  /// week before it met the goal on average, a day without steps counting as
  /// zero, until the user answers. A goal set or changed in the running week
  /// asks nothing in that week. From the week after, the whole week before
  /// is measured against the goal as it stands now, also the days before it
  /// was set: its steps either reach the new goal on average or they do not.

  HealthStepsGoalRaiseOfferProvider call(DateTime weekStart) =>
      HealthStepsGoalRaiseOfferProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'healthStepsGoalRaiseOfferProvider';
}

/// The last met week the user answered the offer for, as yyyymmdd of its
/// first day, saved on the device.

@ProviderFor(HealthStepsGoalRaiseAnswer)
final healthStepsGoalRaiseAnswerProvider =
    HealthStepsGoalRaiseAnswerProvider._();

/// The last met week the user answered the offer for, as yyyymmdd of its
/// first day, saved on the device.
final class HealthStepsGoalRaiseAnswerProvider
    extends $NotifierProvider<HealthStepsGoalRaiseAnswer, int?> {
  /// The last met week the user answered the offer for, as yyyymmdd of its
  /// first day, saved on the device.
  HealthStepsGoalRaiseAnswerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthStepsGoalRaiseAnswerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthStepsGoalRaiseAnswerHash();

  @$internal
  @override
  HealthStepsGoalRaiseAnswer create() => HealthStepsGoalRaiseAnswer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$healthStepsGoalRaiseAnswerHash() =>
    r'e6042050592de0b986614cef13c5d6c80bc40ca4';

/// The last met week the user answered the offer for, as yyyymmdd of its
/// first day, saved on the device.

abstract class _$HealthStepsGoalRaiseAnswer extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
