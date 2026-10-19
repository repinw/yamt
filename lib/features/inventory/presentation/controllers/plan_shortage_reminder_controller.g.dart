// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_shortage_reminder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The day-before reminder for missing plan ingredients. Its state is the
/// settings: on or off (on until the user turns it off), the time of day in
/// minutes after midnight, the plan days the user answered already, and
/// whether the app asked for the notification permission.

@ProviderFor(PlanShortageReminderController)
final planShortageReminderControllerProvider =
    PlanShortageReminderControllerProvider._();

/// The day-before reminder for missing plan ingredients. Its state is the
/// settings: on or off (on until the user turns it off), the time of day in
/// minutes after midnight, the plan days the user answered already, and
/// whether the app asked for the notification permission.
final class PlanShortageReminderControllerProvider
    extends
        $NotifierProvider<
          PlanShortageReminderController,
          PlanShortageReminderSettings
        > {
  /// The day-before reminder for missing plan ingredients. Its state is the
  /// settings: on or off (on until the user turns it off), the time of day in
  /// minutes after midnight, the plan days the user answered already, and
  /// whether the app asked for the notification permission.
  PlanShortageReminderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planShortageReminderControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planShortageReminderControllerHash();

  @$internal
  @override
  PlanShortageReminderController create() => PlanShortageReminderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanShortageReminderSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanShortageReminderSettings>(value),
    );
  }
}

String _$planShortageReminderControllerHash() =>
    r'20907dd91adc1551be0a092b28a85d353e86436b';

/// The day-before reminder for missing plan ingredients. Its state is the
/// settings: on or off (on until the user turns it off), the time of day in
/// minutes after midnight, the plan days the user answered already, and
/// whether the app asked for the notification permission.

abstract class _$PlanShortageReminderController
    extends $Notifier<PlanShortageReminderSettings> {
  PlanShortageReminderSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<PlanShortageReminderSettings, PlanShortageReminderSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                PlanShortageReminderSettings,
                PlanShortageReminderSettings
              >,
              PlanShortageReminderSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the system blocks the day-before reminder while it is on: its
/// notifications are off or its channel is muted. Only once the app asked
/// for the permission, since the system has no answer before. Keeps the
/// last answer while it checks again; false before the first answer and
/// when the check fails: the reminder still tries to show.

@ProviderFor(planShortageReminderBlocked)
final planShortageReminderBlockedProvider =
    PlanShortageReminderBlockedProvider._();

/// Whether the system blocks the day-before reminder while it is on: its
/// notifications are off or its channel is muted. Only once the app asked
/// for the permission, since the system has no answer before. Keeps the
/// last answer while it checks again; false before the first answer and
/// when the check fails: the reminder still tries to show.

final class PlanShortageReminderBlockedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the system blocks the day-before reminder while it is on: its
  /// notifications are off or its channel is muted. Only once the app asked
  /// for the permission, since the system has no answer before. Keeps the
  /// last answer while it checks again; false before the first answer and
  /// when the check fails: the reminder still tries to show.
  PlanShortageReminderBlockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planShortageReminderBlockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planShortageReminderBlockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return planShortageReminderBlocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$planShortageReminderBlockedHash() =>
    r'f5e56cf9728f765e70f063e80ac6af783c966ee2';

/// The day-before reminders the open plans need now; none while the
/// reminder is off.

@ProviderFor(planShortageReminderPlan)
final planShortageReminderPlanProvider = PlanShortageReminderPlanProvider._();

/// The day-before reminders the open plans need now; none while the
/// reminder is off.

final class PlanShortageReminderPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanShortageReminder>>,
          List<PlanShortageReminder>,
          FutureOr<List<PlanShortageReminder>>
        >
    with
        $FutureModifier<List<PlanShortageReminder>>,
        $FutureProvider<List<PlanShortageReminder>> {
  /// The day-before reminders the open plans need now; none while the
  /// reminder is off.
  PlanShortageReminderPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planShortageReminderPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planShortageReminderPlanHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanShortageReminder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanShortageReminder>> create(Ref ref) {
    return planShortageReminderPlan(ref);
  }
}

String _$planShortageReminderPlanHash() =>
    r'0b4908081ddab60b14b2033f0ee101e8f946fc43';
