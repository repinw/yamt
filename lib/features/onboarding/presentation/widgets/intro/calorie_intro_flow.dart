import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_intro_controller.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_chapter_accent.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'calorie_intro_finish_handler.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'calorie_intro_pages.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_backdrop.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_chrome.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_start_day_selector.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'intro_chapter_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Full-screen calorie onboarding intro built on `IntroductionScreen`.
class CalorieIntroFlow extends ConsumerStatefulWidget {
  /// Creates the calorie intro flow.
  const new({required this.initialSettings, super.key});

  /// Initial calorie settings used to seed the calculator.
  final CalorieGoalSettings initialSettings;

  @override
  ConsumerState<CalorieIntroFlow> createState() => _CalorieIntroFlowState();
}

class _CalorieIntroFlowState extends ConsumerState<CalorieIntroFlow> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();

  CalorieGoalCalculatorFormControllerProvider get _formProvider =>
      calorieGoalCalculatorFormControllerProvider(
        widget.initialSettings.calculatorProfile,
        useEmptyDefaults: true,
      );

  CalorieIntroController get _introController =>
      ref.read(calorieIntroControllerProvider.notifier);

  DateTime get _now => ref.read(clockProvider)();

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// The target wheel starts on the current weight. Continuing without moving
  /// it keeps that weight, so maintaining needs no scroll away and back.
  void _acceptUntouchedTargetWeight() {
    final formState = ref.read(_formProvider);
    final isTargetPage =
        ref.read(calorieIntroControllerProvider).currentPage ==
        CalorieIntroPage.target;
    if (!isTargetPage ||
        formState.targetWeightKgText.isNotEmpty ||
        formState.weightKgText.isEmpty) {
      return;
    }
    ref
        .read(_formProvider.notifier)
        .updateTargetWeightKg(formState.weightKgText);
  }

  Future<void> _handleNext() async {
    _dismissKeyboard();
    _acceptUntouchedTargetWeight();
    final targetPage = _introController.next(ref.read(_formProvider));
    if (targetPage == null) {
      return;
    }
    // Each chapter lands harder than the one before it.
    AppHapticFeedback.risingImpact(
      targetPage,
      CalorieIntroPage.values.length - 1,
    );
    await _introKey.currentState?.animateScroll(targetPage);
  }

  Future<void> _handleBack() async {
    _dismissKeyboard();
    final targetPage = _introController.back(ref.read(_formProvider));
    if (targetPage == null) {
      return;
    }
    await _introKey.currentState?.animateScroll(targetPage);
  }

  void _handleLogin() {
    _dismissKeyboard();
    unawaited(context.push('${AppRoutes.welcome}?from=onboarding'));
  }

  Future<void> _handleFinish(CalorieGoalOnboardingFinishFlow finishFlow) async {
    await CalorieIntroFinishHandler(
      finishFlow: finishFlow,
      introController: _introController,
      now: () => _now,
    ).finish(
      context: context,
      formState: ref.read(_formProvider),
      startDate: ref.read(calorieIntroControllerProvider).startDate,
      isMounted: () => mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final formState = ref.watch(_formProvider);
    final finishFlow = ref.watch(calorieGoalOnboardingFinishFlowProvider);
    final introState = ref.watch(calorieIntroControllerProvider);
    final isSaving = introState.isSaving || formState.isSaving;

    final page = introState.currentPage;
    final accent = page.accent.resolve(context);
    final counterAccent = page.accent.counterpart.resolve(context);
    final nextLabel = page.nextActionLabel(l10n) ?? l10n.onboardingNextAction;
    final finishLabel = introStartActionLabel(
      l10n,
      today: _now,
      startDate: introState.startDate,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );

    return PopScope(
      canPop: introState.allowRouteExit,
      child: Stack(
        children: [
          Positioned.fill(
            child: IntroBackdrop(accent: accent, counterAccent: counterAccent),
          ),
          IntroductionScreen(
            key: _introKey,
            rawPages: buildCalorieIntroPages(
              context: context,
              l10n: l10n,
              formState: formState,
              formNotifier: ref.read(_formProvider.notifier),
              showErrors: introState.showErrors,
              today: _now,
              startDate: introState.startDate,
              onStartDateChanged: _introController.selectStartDate,
              onStart: _handleNext,
              onLogin: _handleLogin,
            ),
            onChange: _introController.syncPage,
            freeze: true,
            overrideDone: (context, _) => FilledButton(
              key: CalorieGoalOnboardingKeys.introFinishAction,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
              ),
              onPressed: isSaving
                  ? null
                  : () => unawaited(_handleFinish(finishFlow)),
              child: isSaving
                  ? SizedBox.square(
                      dimension: AppSizes.inlineProgressIndicator,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.progressStrokeWidth,
                        color: colors.onPrimary,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(finishLabel, maxLines: 1),
                    ),
            ),
            showBackButton: introState.showsBackAction,
            showNextButton: introState.showsNextAction,
            next: Text(nextLabel),
            back: Text(MaterialLocalizations.of(context).backButtonTooltip),
            globalHeader: page.chapterNumber == null
                ? null
                : IntroChapterChrome(
                    page: page,
                    category: page.categoryName(l10n),
                    counterLabel: page.counter(l10n),
                  ),
            skipOrBackFlex: 0,
            dotsFlex: 0,
            overrideNext: (context, _) => OutlinedButton(
              key: CalorieGoalOnboardingKeys.introNextAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
                side: BorderSide(
                  color: accent.withValues(
                    alpha: AppIntroLayout.controlBorderOpacity,
                  ),
                ),
              ),
              onPressed: () => unawaited(_handleNext()),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(nextLabel, maxLines: 1),
              ),
            ),
            overrideBack: (context, _) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: OutlinedButton(
                key: CalorieGoalOnboardingKeys.introBackAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  minimumSize: const Size.square(AppSizes.minTapTarget),
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(
                      alpha: AppIntroLayout.controlBorderOpacity,
                    ),
                  ),
                ),
                onPressed: () => unawaited(_handleBack()),
                child: Tooltip(
                  message: MaterialLocalizations.of(context).backButtonTooltip,
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
            globalBackgroundColor: Colors.transparent,
            customProgress: const SizedBox.shrink(),
            isProgressTap: false,
            safeAreaList: const [true, true, true, true],
          ),
        ],
      ),
    );
  }
}
