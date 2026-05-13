import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/domain/onboarding_catch_up_calculator.dart';

const _uuid = Uuid();
const _minimumPlaceholderKcal = 100.0;

/// Writes estimated calorie entries for same-day onboarding catch-up.
class CalorieGoalOnboardingCatchUpPlaceholderWriter {
  /// Creates placeholder writer.
  const CalorieGoalOnboardingCatchUpPlaceholderWriter({
    required CalorieLogRepositoryContract logRepository,
    required bool Function() isMounted,
    String Function()? idGenerator,
  }) : _logRepository = logRepository,
       _isMounted = isMounted,
       _idGenerator = idGenerator ?? _defaultId;

  final CalorieLogRepositoryContract _logRepository;
  final bool Function() _isMounted;
  final String Function() _idGenerator;

  /// Creates placeholder entries needed to align today with the estimate.
  Future<bool> writePlaceholders({
    required DateTime now,
    required double dailyGoalKcal,
    required CalorieGoalOnboardingCatchUpEstimate estimate,
    required String placeholderName,
  }) async {
    final normalizedToday = normalizeDiaryDay(now);
    final entries = await _logRepository.readEntriesForDay(normalizedToday);
    if (!_isMounted()) {
      return false;
    }

    final loggedKcalSoFar = entries.fold<double>(0, (sum, entry) {
      if (entry.loggedAt.isAfter(now)) {
        return sum;
      }
      return sum + entry.totalKcal;
    });

    final desiredTotalKcal = calculateOnboardingCatchUpKcal(
      dailyGoalKcal: dailyGoalKcal,
      now: now,
      estimate: estimate,
    );
    final remainingKcal = desiredTotalKcal - loggedKcalSoFar;

    if (remainingKcal < _minimumPlaceholderKcal || placeholderName.isEmpty) {
      return true;
    }

    final perMeal = distributeKcalAcrossMeals(
      totalKcal: remainingKcal,
      now: now,
    );
    for (final entry in perMeal.entries) {
      if (entry.value < 1) {
        continue;
      }
      final placeholder = CalorieEntry.placeholder(
        id: _idGenerator(),
        name: placeholderName,
        mealType: entry.key,
        totalKcal: entry.value,
        loggedAt: mealMidpointForDay(entry.key, normalizedToday),
      );
      final placeholderSaved = await _logRepository.saveEntryForCurrentUser(
        placeholder,
      );
      // TODO: Add repository-level transactional writes. If a later placeholder
      // fails, earlier placeholder entries may already be persisted.
      if (!placeholderSaved || !_isMounted()) {
        return false;
      }
    }
    return true;
  }
}

String _defaultId() => _uuid.v4();
