import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';

/// Immutable state of the calorie onboarding intro.
@immutable
class CalorieIntroState {
  /// Creates intro state.
  const new({
    this.page = 0,
    this.showErrors = false,
    this.allowRouteExit = false,
    this.isSaving = false,
  });

  /// Pages in display order.
  static const List<CalorieIntroPage> pages = CalorieIntroPage.values;

  /// Current page index.
  final int page;

  /// Whether validation errors should be shown.
  final bool showErrors;

  /// Whether leaving the onboarding route is allowed.
  final bool allowRouteExit;

  /// Whether the finish action is saving.
  final bool isSaving;

  /// Total page count.
  int get totalPages => pages.length;

  /// Current page.
  CalorieIntroPage get currentPage => pages[page];

  /// Whether the shared next control should be visible.
  bool get showsNextAction =>
      currentPage != CalorieIntroPage.welcome &&
      currentPage != CalorieIntroPage.summary;

  /// Whether the back control should be visible.
  bool get showsBackAction => page > 0 && !isSaving;

  /// Whether the current page has everything it needs to continue.
  bool isCurrentPageValid(CalorieGoalCalculatorFormState formState) {
    return switch (currentPage) {
      CalorieIntroPage.identity =>
        formState.sexError == null && formState.ageError == null,
      CalorieIntroPage.body =>
        formState.heightError == null && formState.weightError == null,
      CalorieIntroPage.target =>
        formState.targetWeightError == null &&
            formState.targetWeightKgText.isNotEmpty,
      _ => true,
    };
  }

  /// Copy with.
  CalorieIntroState copyWith({
    int? page,
    bool? showErrors,
    bool? allowRouteExit,
    bool? isSaving,
  }) {
    return CalorieIntroState(
      page: page ?? this.page,
      showErrors: showErrors ?? this.showErrors,
      allowRouteExit: allowRouteExit ?? this.allowRouteExit,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CalorieIntroState &&
        other.page == page &&
        other.showErrors == showErrors &&
        other.allowRouteExit == allowRouteExit &&
        other.isSaving == isSaving;
  }

  @override
  int get hashCode => Object.hash(page, showErrors, allowRouteExit, isSaving);
}
