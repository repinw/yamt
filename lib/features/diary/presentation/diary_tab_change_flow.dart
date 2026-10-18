import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';

/// Tells the diary that the user left its tab, so it opens with today again
/// (#753). It runs after the current build, which may not change the
/// calendar.
void diaryTabLeft(WidgetRef ref) {
  scheduleMicrotask(
    ref.read(diaryCalendarControllerProvider.notifier).showToday,
  );
}
