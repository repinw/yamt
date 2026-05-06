import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

/// Provides calorie entries for one normalized diary day.
final FutureProviderFamily<List<CalorieEntry>, DateTime>
diaryEntriesForDayProvider = FutureProvider.autoDispose
    .family<List<CalorieEntry>, DateTime>((
      ref,
      day,
    ) {
      ref.watch(calorieOverviewRevisionProvider);
      final normalizedDay = normalizeDiaryDay(day);
      return ref
          .watch(calorieLogRepositoryProvider)
          .readEntriesForDay(normalizedDay);
    });
