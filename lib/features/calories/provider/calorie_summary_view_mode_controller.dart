import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'calorie_summary_view_mode_controller.g.dart';

enum CalorieSummaryViewMode { classic, balance }

@Riverpod(keepAlive: true)
class CalorieSummaryViewModeController
    extends _$CalorieSummaryViewModeController {
  static const String _preferenceKey = 'calories_summary_view_mode';

  @override
  CalorieSummaryViewMode build() {
    final preferences = ref.read(appPreferencesProvider);
    final storedMode = preferences.getStringSync(_preferenceKey);
    if (storedMode != null) {
      return _viewModeFromName(storedMode);
    }

    return CalorieSummaryViewMode.balance;
  }

  Future<void> setMode(CalorieSummaryViewMode mode) async {
    if (state == mode) {
      return;
    }

    state = mode;
    await ref.read(appPreferencesProvider).setString(_preferenceKey, mode.name);
  }

  CalorieSummaryViewMode _viewModeFromName(String value) {
    return switch (value) {
      'classic' => CalorieSummaryViewMode.classic,
      'balance' => CalorieSummaryViewMode.balance,
      _ => CalorieSummaryViewMode.balance,
    };
  }
}
