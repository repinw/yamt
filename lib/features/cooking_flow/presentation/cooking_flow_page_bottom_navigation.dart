import 'package:flutter/material.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_page_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds cookflow bottom navigation for the current step.
class CookingFlowPageBottomNavigation extends StatelessWidget {
  /// Creates bottom navigation.
  const CookingFlowPageBottomNavigation({
    required this.step,
    required this.isFinalizingMeal,
    required this.hasValidFinalizeWeight,
    required this.introAllItemsSelected,
    required this.introHasShoppingSelections,
    required this.introHasUnresolvedConflicts,
    required this.introShoppingHandled,
    required this.introShoppingRedirectInProgress,
    required this.onLaterPressed,
    required this.onIntroShoppingPressed,
    required this.onOpenPreparationPressed,
    required this.onOpenCookingPressed,
    required this.onOpenSummaryPressed,
    required this.onOpenFinalizePressed,
    required this.onFinalizePressed,
    super.key,
  });

  /// Current wizard step.
  final CookingFlowStep step;

  /// Whether save is in progress.
  final bool isFinalizingMeal;

  /// Whether finalize input can be saved.
  final bool hasValidFinalizeWeight;

  /// Whether every intro item has a selection.
  final bool introAllItemsSelected;

  /// Whether intro has shopping-list selections.
  final bool introHasShoppingSelections;

  /// Whether intro has unresolved conflicts.
  final bool introHasUnresolvedConflicts;

  /// Whether shopping-list detour has been handled.
  final bool introShoppingHandled;

  /// Whether shopping-list redirect is in progress.
  final bool introShoppingRedirectInProgress;

  /// Later/back callback.
  final VoidCallback onLaterPressed;

  /// Shopping-list CTA callback.
  final VoidCallback onIntroShoppingPressed;

  /// Opens preparation step.
  final VoidCallback onOpenPreparationPressed;

  /// Opens cooking step.
  final VoidCallback onOpenCookingPressed;

  /// Opens summary step.
  final VoidCallback onOpenSummaryPressed;

  /// Opens finalize step.
  final VoidCallback onOpenFinalizePressed;

  /// Saves meal.
  final VoidCallback onFinalizePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (step) {
      CookingFlowStep.start => CookingFlowPhaseBottomDualAction(
        secondaryLabel: l10n.cookflowLaterButton,
        onSecondaryPressed: onLaterPressed,
        primaryLabel: _introPrimaryButtonLabel(l10n),
        onPrimaryPressed: _introPrimaryButtonPressed,
        primaryLeadingIcon: _introPrimaryButtonLeadingIcon,
        primaryTrailingIcon: _introPrimaryButtonTrailingIcon,
      ),
      CookingFlowStep.preparation => CookingFlowPhaseBottomAction(
        label: l10n.cookflowContinueButton,
        onPressed: onOpenCookingPressed,
      ),
      CookingFlowStep.cooking => CookingFlowPhaseBottomAction(
        label: l10n.cookflowContinueButton,
        onPressed: onOpenSummaryPressed,
      ),
      CookingFlowStep.summary => CookingFlowPhaseBottomAction(
        label: l10n.cookflowContinueButton,
        onPressed: onOpenFinalizePressed,
      ),
      CookingFlowStep.finalize => CookingFlowPhaseBottomAction(
        label: isFinalizingMeal
            ? l10n.cookflowSavingMealButton
            : l10n.cookflowSaveMealButton,
        onPressed: isFinalizingMeal || !hasValidFinalizeWeight
            ? null
            : onFinalizePressed,
        icon: Icons.check_circle_outline_rounded,
      ),
      CookingFlowStep.success => const SizedBox.shrink(),
    };
  }

  VoidCallback? get _introPrimaryButtonPressed {
    if (introHasUnresolvedConflicts || introShoppingRedirectInProgress) {
      return null;
    }
    if (!introAllItemsSelected) {
      return null;
    }
    if (introHasShoppingSelections && !introShoppingHandled) {
      return onIntroShoppingPressed;
    }
    return onOpenPreparationPressed;
  }

  String _introPrimaryButtonLabel(AppLocalizations l10n) {
    if (introHasUnresolvedConflicts) {
      return l10n.cookflowResolveConflictsButton;
    }
    if (introHasShoppingSelections &&
        introAllItemsSelected &&
        !introShoppingHandled) {
      return l10n.cookflowShoppingListContinueButton;
    }
    return l10n.cookflowStartButton;
  }

  IconData? get _introPrimaryButtonLeadingIcon {
    if (introHasUnresolvedConflicts) {
      return Icons.warning_amber_rounded;
    }
    if (introHasShoppingSelections &&
        introAllItemsSelected &&
        !introShoppingHandled) {
      return Icons.shopping_cart_outlined;
    }
    return null;
  }

  IconData? get _introPrimaryButtonTrailingIcon {
    if (introHasUnresolvedConflicts) {
      return null;
    }
    if (introHasShoppingSelections &&
        introAllItemsSelected &&
        !introShoppingHandled) {
      return null;
    }
    return Icons.play_arrow_rounded;
  }
}
