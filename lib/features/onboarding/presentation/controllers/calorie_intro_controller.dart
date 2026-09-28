import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/models/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/domain/tracking_start_day.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_state.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

part 'calorie_intro_controller.g.dart';

const _logName = 'CalorieIntroController';

/// How long finishing waits for the data key of a new guest account.
const _dataKeyTimeout = Duration(seconds: 20);

/// Outcome of finishing the intro.
enum CalorieIntroFinishResult {
  /// Everything is saved; the intro may close.
  finished,

  /// There was no connection. The answers stay, and the user can try again.
  offline,

  /// Saving failed for another reason.
  failed,
}

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

  /// Saves everything the intro collected and allows leaving the route.
  ///
  /// The intro keeps its answers in memory. A visitor without an account gets
  /// a guest account only here, so opening the app without finishing creates
  /// no Firebase user. The goal is saved once the data key of that account is
  /// ready, so it is stored encrypted like all private data.
  Future<CalorieIntroFinishResult> finish(
    CalorieCalculatorProfile profile,
  ) async {
    final link = ref.keepAlive();
    final finishFlow = ref.listen(
      calorieGoalOnboardingFinishFlowProvider,
      (previous, next) {},
    );
    state = state.copyWith(isSaving: true);
    var result = CalorieIntroFinishResult.failed;
    try {
      if (await _signInAndSave(profile, finishFlow.read)) {
        result = CalorieIntroFinishResult.finished;
      }
    } on Object catch (error, stackTrace) {
      log(
        'Finishing the calorie intro failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AuthOfflineException || error is TimeoutException) {
        result = CalorieIntroFinishResult.offline;
      }
    } finally {
      finishFlow.close();
      link.close();
    }
    if (ref.mounted) {
      state = result == CalorieIntroFinishResult.finished
          ? state.copyWith(allowRouteExit: true)
          : state.copyWith(isSaving: false);
    }
    return result;
  }

  Future<bool> _signInAndSave(
    CalorieCalculatorProfile profile,
    CalorieGoalOnboardingFinishFlow Function() finishFlow,
  ) async {
    final userId = await _signedInUserId();
    if (!ref.mounted) {
      return false;
    }
    final saved = await finishFlow().saveGoal(
      CalorieGoalOnboardingFinishRequest(
        profile: profile,
        today: ref.read(clockProvider)(),
        startDate: state.startDate,
      ),
    );
    if (!saved || !ref.mounted) {
      return false;
    }
    await markCalorieGoalOnboardingCompleted(ref, userId: userId);
    return ref.mounted;
  }

  /// Signs in a guest when nobody is signed in, and returns the user id once
  /// the data key of that user is ready.
  Future<String> _signedInUserId() async {
    // A failed attempt, for example offline, leaves the session in an error.
    // A new attempt loads it again.
    if (ref.read(userDataKeySessionProvider).hasError) {
      ref.invalidate(userDataKeySessionProvider);
    }
    final dataKeyReady = Completer<String>();
    var signInStarted = false;
    final subscription = ref.listen(userDataKeySessionProvider, (
      previous,
      next,
    ) {
      if (dataKeyReady.isCompleted) {
        return;
      }
      // The first call shows the state from before the invalidation above,
      // which may still carry the old error.
      if (previous != null && next.hasError) {
        dataKeyReady.completeError(next.error!, next.stackTrace);
        return;
      }
      switch (next) {
        case AsyncData(value: UserDataKeyReady(:final uid)):
          dataKeyReady.complete(uid);
        case AsyncData(value: UserDataKeyRecoveryRequired()):
          dataKeyReady.completeError(
            StateError('The data key of the new account needs recovery.'),
          );
        case AsyncData(value: UserDataKeySignedOut()) when !signInStarted:
          signInStarted = true;
          unawaited(_signInGuest(dataKeyReady));
        case _:
          break;
      }
    }, fireImmediately: true);
    try {
      return await dataKeyReady.future.timeout(_dataKeyTimeout);
    } finally {
      subscription.close();
    }
  }

  Future<void> _signInGuest(Completer<String> dataKeyReady) async {
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
    } on Object catch (error, stackTrace) {
      if (!dataKeyReady.isCompleted) {
        dataKeyReady.completeError(error, stackTrace);
      }
    }
  }

  bool _skipsPace(CalorieGoalCalculatorFormState formState, int page) {
    return page >= 0 &&
        page < state.totalPages &&
        CalorieIntroState.pages[page] == CalorieIntroPage.pace &&
        formState.goalMode == CalorieGoalMode.maintain;
  }
}
