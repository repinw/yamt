import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

/// Persisted classic-summary adjustment preferences.
class CalorieSummaryClassicAdjustments {
  /// Creates persisted classic-summary adjustment preferences.
  const CalorieSummaryClassicAdjustments({
    required this.includeActivityDelta,
    required this.includeCarryover,
  });

  /// Whether classic mode should include activity delta when available.
  final bool includeActivityDelta;

  /// Whether classic mode should include carryover when available.
  final bool includeCarryover;

  /// Returns a copy with the provided field overrides.
  CalorieSummaryClassicAdjustments copyWith({
    bool? includeActivityDelta,
    bool? includeCarryover,
  }) {
    return CalorieSummaryClassicAdjustments(
      includeActivityDelta: includeActivityDelta ?? this.includeActivityDelta,
      includeCarryover: includeCarryover ?? this.includeCarryover,
    );
  }
}

/// Stores global classic-summary adjustment preferences.
class CalorieSummaryClassicAdjustmentsController
    extends Notifier<CalorieSummaryClassicAdjustments> {
  static const _activityDeltaPreferenceKey =
      'calories_summary_classic_include_activity_delta';
  static const _carryoverPreferenceKey =
      'calories_summary_classic_include_carryover';

  @override
  CalorieSummaryClassicAdjustments build() {
    final preferences = ref.read(appPreferencesProvider);
    return CalorieSummaryClassicAdjustments(
      includeActivityDelta: _readBoolPreference(
        preferences,
        _activityDeltaPreferenceKey,
        fallback: true,
      ),
      includeCarryover: _readBoolPreference(
        preferences,
        _carryoverPreferenceKey,
        fallback: false,
      ),
    );
  }

  /// Persists whether classic mode should include activity delta.
  Future<void> setIncludeActivityDelta({required bool value}) async {
    if (state.includeActivityDelta == value) {
      return;
    }

    state = state.copyWith(includeActivityDelta: value);
    await ref
        .read(appPreferencesProvider)
        .setString(_activityDeltaPreferenceKey, _encodeBool(value: value));
  }

  /// Persists whether classic mode should include carryover.
  Future<void> setIncludeCarryover({required bool value}) async {
    if (state.includeCarryover == value) {
      return;
    }

    state = state.copyWith(includeCarryover: value);
    await ref
        .read(appPreferencesProvider)
        .setString(_carryoverPreferenceKey, _encodeBool(value: value));
  }

  bool _readBoolPreference(
    AppPreferences preferences,
    String key, {
    required bool fallback,
  }) {
    final storedValue = preferences.getStringSync(key);
    return switch (storedValue) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };
  }

  String _encodeBool({required bool value}) => value ? 'true' : 'false';
}

/// Provides persisted classic-summary adjustment preferences.
final calorieSummaryClassicAdjustmentsControllerProvider =
    NotifierProvider<
      CalorieSummaryClassicAdjustmentsController,
      CalorieSummaryClassicAdjustments
    >(CalorieSummaryClassicAdjustmentsController.new);
