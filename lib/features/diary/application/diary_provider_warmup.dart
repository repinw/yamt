import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_calendar_controller.dart';

part 'diary_provider_warmup.g.dart';

/// Keeps lightweight diary clock dependencies warm while the page is open.
@riverpod
void diaryProviderWarmup(Ref ref) {
  ref.watch(diaryProviderWarmupTodayProvider);
}

/// Current diary day that should be warmed.
@riverpod
DateTime diaryProviderWarmupToday(Ref ref) {
  return ref.watch(diaryCalendarControllerProvider).today;
}
