part of 'calorie_goal_calculator_flow.dart';

extension _CalorieGoalCalculatorFlowLayout on _CalorieGoalCalculatorFlowState {
  Widget _buildOnboardingScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: AppInsets.page,
              child: SingleChildScrollView(
                child: _buildCard(
                  context: context,
                  l10n: l10n,
                  showDescription: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: _buildCard(context: context, l10n: l10n, showDescription: false),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool showDescription,
  }) {
    final colors = Theme.of(context).colorScheme;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final state = ref.watch(formProvider);
    final currentStep = _effectiveStep(state.goalMode);
    final visibleSteps = _visibleSteps(state.goalMode);
    final currentStepIndex = visibleSteps.indexOf(currentStep) + 1;
    final totalSteps = visibleSteps.length;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isOnboarding
                    ? l10n.caloriesCalculatorOnboardingTitle
                    : l10n.caloriesCalculatorSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (showDescription) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.caloriesCalculatorOnboardingSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.caloriesCalculatorStepProgress(
                  currentStepIndex,
                  totalSteps,
                ),
                key: CalorieGoalCalculatorSheetKeys.stepCounter,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _StepPanel(
                  key: ValueKey<_CalculatorOnboardingStep>(currentStep),
                  title: _titleForStep(currentStep, l10n),
                  child: _buildStepContent(
                    context: context,
                    l10n: l10n,
                    state: state,
                    step: currentStep,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildLeadingAction(
                      context: context,
                      l10n: l10n,
                      state: state,
                      currentStep: currentStep,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: currentStep == _CalculatorOnboardingStep.results
                        ? FilledButton(
                            key: CalorieGoalCalculatorSheetKeys.saveButton,
                            onPressed: state.canSave && !state.isSaving
                                ? _save
                                : null,
                            child: state.isSaving
                                ? const SizedBox.square(
                                    dimension: AppSizes.inlineProgressIndicator,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppSizes.progressStrokeWidth,
                                    ),
                                  )
                                : Text(l10n.caloriesCalculatorSaveAction),
                          )
                        : FilledButton(
                            key: CalorieGoalCalculatorSheetKeys.nextButton,
                            onPressed: _canContinue(currentStep, state)
                                ? () => _goToNextStep(state.goalMode)
                                : null,
                            child: Text(l10n.caloriesCalculatorNextAction),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingAction({
    required BuildContext context,
    required AppLocalizations l10n,
    required CalorieGoalCalculatorFormState state,
    required _CalculatorOnboardingStep currentStep,
  }) {
    if (currentStep != _CalculatorOnboardingStep.sex) {
      return TextButton(
        key: CalorieGoalCalculatorSheetKeys.backButton,
        onPressed: state.isSaving
            ? null
            : () => _goToPreviousStep(state.goalMode),
        child: Text(l10n.caloriesCalculatorBackAction),
      );
    }

    if (widget.isOnboarding) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: state.isSaving ? null : () => Navigator.of(context).pop(),
      child: Text(l10n.inventoryReceiptReviewCancelAction),
    );
  }
}
