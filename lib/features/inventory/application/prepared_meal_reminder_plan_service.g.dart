// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_reminder_plan_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The reminder plans service.

@ProviderFor(preparedMealReminderPlanService)
final preparedMealReminderPlanServiceProvider =
    PreparedMealReminderPlanServiceProvider._();

/// The reminder plans service.

final class PreparedMealReminderPlanServiceProvider
    extends
        $FunctionalProvider<
          PreparedMealReminderPlanService,
          PreparedMealReminderPlanService,
          PreparedMealReminderPlanService
        >
    with $Provider<PreparedMealReminderPlanService> {
  /// The reminder plans service.
  PreparedMealReminderPlanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealReminderPlanServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealReminderPlanServiceHash();

  @$internal
  @override
  $ProviderElement<PreparedMealReminderPlanService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealReminderPlanService create(Ref ref) {
    return preparedMealReminderPlanService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealReminderPlanService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealReminderPlanService>(
        value,
      ),
    );
  }
}

String _$preparedMealReminderPlanServiceHash() =>
    r'4fb6684f66287f138957d13f475f0c60d93c5365';
