import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

const _preferenceKeyPrefix = 'calorie_today_weight_prompt_dismissed_day';
const _localPreferenceScope = 'local';

/// Stores the last diary day where the user dismissed today's weight prompt.
class CalorieTodayWeightPromptDismissalController extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authStateChangesProvider);
    return ref.read(appPreferencesProvider).getStringSync(_preferenceKey);
  }

  /// Whether the prompt has already been dismissed for [day].
  bool isDismissedForDay(DateTime day) {
    return state == diaryDayKey(day);
  }

  /// Dismiss prompt for [day].
  Future<void> dismissForDay(DateTime day) async {
    final dayKey = diaryDayKey(day);
    if (state == dayKey) {
      return;
    }

    state = dayKey;
    await ref.read(appPreferencesProvider).setString(_preferenceKey, dayKey);
  }

  String get _preferenceKey {
    return '$_preferenceKeyPrefix:${_currentPreferenceScope()}';
  }

  String _currentPreferenceScope() {
    try {
      final userId = ref.read(authStateChangesProvider).asData?.value?.uid;
      final normalizedUserId = userId?.trim();
      if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
        return normalizedUserId;
      }
    } on Object catch (_) {
      // Treat missing auth context as local-only dismissal state.
    }
    return _localPreferenceScope;
  }
}

/// Provides the dismissed diary-day key for today's weight prompt.
final calorieTodayWeightPromptDismissalControllerProvider =
    NotifierProvider<CalorieTodayWeightPromptDismissalController, String?>(
      CalorieTodayWeightPromptDismissalController.new,
    );
