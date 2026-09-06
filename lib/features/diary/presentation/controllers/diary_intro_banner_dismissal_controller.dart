import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';

part 'diary_intro_banner_dismissal_controller.g.dart';

/// Tracks whether the week 1 diary intro banner has been dismissed.
@riverpod
class DiaryIntroBannerDismissalController
    extends _$DiaryIntroBannerDismissalController {
  @override
  bool build() {
    final preferences = ref.watch(appPreferencesProvider);
    return DiaryIntroPreferences.isBannerDismissed(preferences);
  }

  /// Dismiss the intro banner permanently.
  Future<void> dismiss() async {
    if (state) {
      return;
    }
    state = true;
    final preferences = ref.read(appPreferencesProvider);
    await DiaryIntroPreferences.markBannerDismissed(preferences);
  }
}
