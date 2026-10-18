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
    r'9098f16bfb29ce4a4c928c69ba5d91d9f7c70c54';

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
