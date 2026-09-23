import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/domain/tracking_start_day.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_state.dart';

part 'calorie_intro_controller.g.dart';

/// State controller for the calorie onboarding intro.
@riverpod
class CalorieIntroController extends _$CalorieIntroController {
  @override
  CalorieIntroState build() {
    final now = ref.watch(clockProvider)();
    return CalorieIntroState(startDate: defaultTrackingStartDay(now));
  }

  /// Selects the day the first tracked week starts.
  void selectStartDate(DateTime day) {
    state = state.copyWith(startDate: normalizeDiaryDay(day));
  }

  /// Moves to the next page. Returns the target index when it changed.
  int? next(CalorieGoalCalculatorFormState formState) {
    if (state.page >= state.totalPages - 1) {
      return null;
    }
    if (!state.isCurrentPageValid(formState)) {
      state = state.copyWith(showErrors: true);
      return null;
    }

    var nextPage = state.page + 1;
    if (_skipsPace(formState, nextPage)) {
      nextPage++;
    }

    state = state.copyWith(page: nextPage, showErrors: false);
    return state.page;
  }

  /// Moves to the previous page. Returns the target index when it changed.
  int? back(CalorieGoalCalculatorFormState formState) {
    if (state.page <= 0) {
      return null;
    }

    var previousPage = state.page - 1;
    if (_skipsPace(formState, previousPage)) {
      previousPage--;
    }

    state = state.copyWith(page: previousPage, showErrors: false);
    return state.page;
  }

  /// Records the page the intro screen scrolled to.
  void syncPage(int page) {
    if (page == state.page || page < 0 || page >= state.totalPages) {
      return;
    }
    state = state.copyWith(page: page, showErrors: false);
  }

  /// Hides currently visible validation errors.
  void clearErrors() {
    if (!state.showErrors) {
      return;
    }
    state = state.copyWith(showErrors: false);
  }

  /// Starts saving.
  void startSaving() {
    state = state.copyWith(isSaving: true);
  }

  /// Stops saving after a failed save.
  void stopSavingAfterFailure() {
    state = state.copyWith(isSaving: false);
  }

  /// Allows leaving the onboarding route after a successful save.
  void markRouteExitAllowed() {
    state = state.copyWith(allowRouteExit: true);
  }

  bool _skipsPace(CalorieGoalCalculatorFormState formState, int page) {
    return page >= 0 &&
        page < state.totalPages &&
        CalorieIntroState.pages[page] == CalorieIntroPage.pace &&
        formState.goalMode == CalorieGoalMode.maintain;
  }
}
