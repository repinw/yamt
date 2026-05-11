part of '../meal_template_detail_page.dart';

class _MealTemplateFooter extends StatelessWidget {
  const _MealTemplateFooter({
    required this.hasAssignmentChanges,
    required this.isCreatingMeal,
    required this.isSavingTemplate,
    required this.canCreateMeal,
    required this.onSaveTemplatePressed,
    required this.onAddIngredientsToShoppingListPressed,
    required this.onCreateMealPressed,
  });

  final bool hasAssignmentChanges;
  final bool isCreatingMeal;
  final bool isSavingTemplate;
  final bool canCreateMeal;
  final Future<void> Function()? onSaveTemplatePressed;
  final Future<void> Function() onAddIngredientsToShoppingListPressed;
  final Future<void> Function() onCreateMealPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);
    final addIngredientsLabel =
        l10n.preparedMealTemplateDetailIngredientsToShoppingListAction;
    final handleAddIngredientsToShoppingList =
        onAddIngredientsToShoppingListPressed;
    void addIngredientsToShoppingList() {
      unawaited(handleAddIngredientsToShoppingList());
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              AppInventoryEditorialSurfaces.ambientBoxShadow(
                colors,
                blurRadius: 32,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppInventoryEditorial.glassBlur,
                sigmaY: AppInventoryEditorial.glassBlur,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest.withValues(alpha: 0.95),
                  borderRadius: radius,
                  border: Border.all(
                    color: AppInventoryEditorialSurfaces.ghostBorder(
                      colors,
                    ).withValues(alpha: 0.45),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasAssignmentChanges) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isSavingTemplate || isCreatingMeal
                                ? null
                                : () async {
                                    await onSaveTemplatePressed?.call();
                                  },
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              isSavingTemplate
                                  ? l10n.preparedMealTemplateDetailSavingAction
                                  : l10n.preparedMealTemplateDetailSaveAction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _FooterOutlineActionButton(
                              icon: Icons.shopping_cart_rounded,
                              label: addIngredientsLabel,
                              onPressed: isSavingTemplate || isCreatingMeal
                                  ? null
                                  : addIngredientsToShoppingList,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _FooterPrimaryActionButton(
                              icon: Icons.restaurant_rounded,
                              label: l10n.preparedMealCreateAction,
                              onPressed:
                                  isSavingTemplate ||
                                      isCreatingMeal ||
                                      !canCreateMeal
                                  ? null
                                  : () async {
                                      await onCreateMealPressed();
                                    },
                            ),
                          ),
                        ],
                      ),
                      if (!canCreateMeal) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.preparedMealTemplateDetailCreateMealHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterPrimaryActionButton extends StatelessWidget {
  const _FooterPrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    final radius = BorderRadius.circular(AppRadius.xl);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? AppInventoryEditorialSurfaces.soulGradient(colors)
            : LinearGradient(
                colors: [
                  colors.surfaceContainerHighest,
                  colors.surfaceContainerHighest,
                ],
              ),
        borderRadius: radius,
        boxShadow: isEnabled
            ? [
                AppInventoryEditorialSurfaces.ambientBoxShadow(
                  colors,
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          enableFeedback: false,
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled ? colors.onPrimary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isEnabled
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterOutlineActionButton extends StatelessWidget {
  const _FooterOutlineActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.xl);

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        enableFeedback: false,
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: onPressed == null
                  ? colors.outlineVariant.withValues(alpha: 0.3)
                  : colors.primary,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: onPressed == null
                      ? colors.onSurfaceVariant
                      : colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: onPressed == null
                          ? colors.onSurfaceVariant
                          : colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Defines meal template footer test harness.
@visibleForTesting
class MealTemplateFooterTestHarness extends StatelessWidget {
  /// The meal template footer test harness.
  const MealTemplateFooterTestHarness({
    required this.hasAssignmentChanges,
    required this.isCreatingMeal,
    required this.isSavingTemplate,
    required this.canCreateMeal,
    super.key,
    this.onSaveTemplatePressed,
    this.onAddIngredientsToShoppingListPressed,
    this.onCreateMealPressed,
  });

  /// Whether assignment changes.
  final bool hasAssignmentChanges;

  /// Whether creating meal.
  final bool isCreatingMeal;

  /// Whether saving template.
  final bool isSavingTemplate;

  /// Whether create meal.
  final bool canCreateMeal;

  /// The on save template pressed.
  final Future<void> Function()? onSaveTemplatePressed;

  /// The on add ingredients to shopping list pressed.
  final Future<void> Function()? onAddIngredientsToShoppingListPressed;

  /// The on create meal pressed.
  final Future<void> Function()? onCreateMealPressed;

  @override
  Widget build(BuildContext context) {
    return _MealTemplateFooter(
      hasAssignmentChanges: hasAssignmentChanges,
      isCreatingMeal: isCreatingMeal,
      isSavingTemplate: isSavingTemplate,
      canCreateMeal: canCreateMeal,
      onSaveTemplatePressed: onSaveTemplatePressed ?? Future<void>.value,
      onAddIngredientsToShoppingListPressed:
          onAddIngredientsToShoppingListPressed ?? Future<void>.value,
      onCreateMealPressed: onCreateMealPressed ?? Future<void>.value,
    );
  }
}
