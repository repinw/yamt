import 'dart:developer' show log;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

part 'diary_quick_entry_controller.g.dart';

const _logName = 'DiaryQuickEntryController';

/// A value typed on the quick entry page, in food label order.
enum DiaryQuickEntryValue {
  /// Calories in kcal. The only required value.
  kcal,

  /// Fat in grams.
  fat,

  /// Carbohydrates in grams.
  carbs,

  /// Protein in grams.
  protein,
}

/// Input of the quick entry page.
@immutable
class DiaryQuickEntryState {
  /// Creates the state.
  const new({
    required this.name,
    required this.texts,
    required this.loggedAt,
    required this.mealType,
    required this.today,
    required this.isSaving,
  });

  /// Typed name, empty for the default name.
  final String name;

  /// Typed text of each value.
  final Map<DiaryQuickEntryValue, String> texts;

  /// When the food is logged.
  final DateTime loggedAt;

  /// Meal the food is logged to.
  final MealType mealType;

  /// The current day, the last one the day picker offers.
  final DateTime today;

  /// Whether the entry is being saved.
  final bool isSaving;

  /// The typed number of [value], or null when it is empty or no number.
  double? valueOf(DiaryQuickEntryValue value) {
    return parseNonNegativeDecimalInput(texts[value] ?? '');
  }

  /// The typed calories.
  double? get kcal => valueOf(DiaryQuickEntryValue.kcal);

  /// Whether a macro is still empty, so the entry counts it as 0 g.
  bool get isMissingMacros => DiaryQuickEntryValue.values
      .where((value) => value != DiaryQuickEntryValue.kcal)
      .any((value) => valueOf(value) == null);

  /// Whether the entry can be saved: it needs the calories.
  bool get canSave => kcal != null && !isSaving;

  /// Whether the entry is saved as a plan: its day lies after [today].
  bool get isPlan => isDiaryFutureDay(day: loggedAt, today: today);

  /// Copies the state with the given changes.
  DiaryQuickEntryState copyWith({
    String? name,
    Map<DiaryQuickEntryValue, String>? texts,
    DateTime? loggedAt,
    MealType? mealType,
    bool? isSaving,
  }) {
    return DiaryQuickEntryState(
      name: name ?? this.name,
      texts: texts ?? this.texts,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      today: today,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Holds the input of the quick entry page and saves it as a calorie entry
/// without a food behind it.
@riverpod
class DiaryQuickEntryController extends _$DiaryQuickEntryController {
  static const _uuid = Uuid();

  @override
  DiaryQuickEntryState build({
    required DateTime initialLoggedAt,
    required MealType initialMealType,
  }) {
    // The saver uses its ref after a save, so it stays alive with the page.
    ref.listen(calorieEntrySaverProvider, (_, _) {});
    return DiaryQuickEntryState(
      name: '',
      texts: const {},
      loggedAt: initialLoggedAt,
      mealType: initialMealType,
      today: ref.watch(clockProvider)(),
      isSaving: false,
    );
  }

  /// Sets the typed name.
  void setName(String name) => state = state.copyWith(name: name);

  /// Sets the typed text of [value].
  void setValueText(DiaryQuickEntryValue value, String text) {
    state = state.copyWith(
      texts: Map.unmodifiable({...state.texts, value: text}),
    );
  }

  /// Moves the entry to [day], keeping the current time of day.
  void setLoggedDay(DateTime day) {
    state = state.copyWith(
      loggedAt: loggedAtOnDay(day, now: ref.read(clockProvider)()),
    );
  }

  /// Sets the meal the food is logged to.
  void setMealType(MealType mealType) {
    state = state.copyWith(mealType: mealType);
  }

  /// Saves the typed values as a quick entry named [defaultName] when no
  /// name was typed, as a plan on a future day. Returns the saved entry, or
  /// null when saving failed.
  Future<CalorieEntry?> save({required String defaultName}) async {
    final kcal = state.kcal;
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (kcal == null || state.isSaving || userId == null) {
      return null;
    }
    final name = state.name.trim();
    final entry = buildQuickCalorieEntry(
      id: _uuid.v4(),
      userId: userId,
      name: name.isEmpty ? defaultName : name,
      mealType: state.mealType,
      loggedAt: state.loggedAt,
      now: ref.read(clockProvider)(),
      kcal: kcal,
      protein: state.valueOf(DiaryQuickEntryValue.protein),
      carbs: state.valueOf(DiaryQuickEntryValue.carbs),
      fat: state.valueOf(DiaryQuickEntryValue.fat),
    );
    final saveEntry = ref.read(calorieEntrySaverProvider);
    final plans = ref.read(plannedEntryRepositoryProvider);
    final revision = ref.read(calorieOverviewRevisionProvider.notifier);
    final plannedDay = ref.read(lastPlannedDayProvider.notifier);
    final isPlan = state.isPlan;
    state = state.copyWith(isSaving: true);
    final result = await AsyncValue.guard(() async {
      if (!isPlan) {
        return await saveEntry(entry);
      }
      await plans.savePlannedEntry(entry);
      // The diary dashboards learn about the plan from the revision.
      revision.markChanged();
      plannedDay.planned(entry.loggedAt);
      return true;
    });
    if (result case AsyncError(:final error, :final stackTrace)) {
      log(
        'Failed to save quick entry.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!ref.mounted) {
      return null;
    }
    state = state.copyWith(isSaving: false);
    return result.value == true ? entry : null;
  }
}
