part of 'meal_template_detail_page.dart';

class _MealTemplateDetailContent extends ConsumerWidget {
  const _MealTemplateDetailContent({
    required this.template,
    required this.selectedPortions,
    required this.inventoryItems,
    required this.recipeIngredientAssignments,
    required this.recipeIngredientAmountConversions,
    required this.hasAssignmentChanges,
    required this.isCreatingMeal,
    required this.isSavingTemplate,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
    required this.onAssignmentChanged,
    required this.onCreateMealPressed,
    required this.onAddIngredientsToShoppingListPressed,
    required this.onSaveTemplatePressed,
  });

  static const _maxContentWidth = 760.0;
  static const _footerHeight = 164.0;
  static const _footerHeightWithSave = 220.0;
  static const _topBarContentHeight = 76.0;

  final PreparedMeal template;
  final int selectedPortions;
  final List<InventoryItem> inventoryItems;
  final Map<String, List<String>> recipeIngredientAssignments;
  final Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions;
  final bool hasAssignmentChanges;
  final bool isCreatingMeal;
  final bool isSavingTemplate;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;
  final void Function({
    required String ingredient,
    required List<String> inventoryItemIds,
    required RecipeIngredientAmountConversion? amountConversion,
  })
  onAssignmentChanged;
  final Future<void> Function() onCreateMealPressed;
  final Future<void> Function() onAddIngredientsToShoppingListPressed;
  final Future<void> Function()? onSaveTemplatePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final topBarReservedHeight =
        MediaQuery.paddingOf(context).top + _topBarContentHeight;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final ingredientRows = _buildIngredientRows(
      template: template,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      selectedPortions: selectedPortions,
      ingredientParser: ref.read(templateIngredientParserProvider),
    );
    final canCreateMeal = ingredientRows.isNotEmpty;
    final showFooter = template.recipeIngredients.isNotEmpty;
    final scrollBottomPadding = showFooter
        ? hasAssignmentChanges
              ? _footerHeightWithSave
              : _footerHeight
        : AppSpacing.xxxxl;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
      ),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: topBarReservedHeight,
              bottom: scrollBottomPadding,
            ),
            children: [
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    children: [
                      _MealTemplateHeroSection(
                        templateName: template.name,
                        imageBytes: storedImageBytes,
                        imageUrl: template.imageUrl,
                        portionsLabel: l10n.preparedMealTemplatePortions(
                          selectedPortions,
                        ),
                        basePortionsLabel: l10n
                            .preparedMealTemplateDetailBasePortions(
                              _defaultPortions(template.totalPortions),
                            ),
                        onDecreasePortions: onDecreasePortions,
                        onIncreasePortions: onIncreasePortions,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xxxxl,
                        ),
                        child: ingredientRows.isEmpty
                            ? _MealTemplateEmptyIngredientsCard(
                                message: l10n
                                    .preparedMealTemplateDetailNoIngredients,
                              )
                            : Column(
                                children: [
                                  for (final row in ingredientRows) ...[
                                    _MealTemplateIngredientCard(
                                      row: row,
                                      inventoryItems: inventoryItems,
                                      onAddToShoppingListPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => _addIngredientToShoppingList(
                                              context: context,
                                              ref: ref,
                                              shoppingListLabel:
                                                  _shoppingListLabelForRow(
                                                    row: row,
                                                    inventoryItems:
                                                        inventoryItems,
                                                  ),
                                            ),
                                      onToggleIgnoredPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => _toggleIgnored(
                                              context: context,
                                              ref: ref,
                                              templateId: template.id,
                                              ingredient: row.rawIngredient!,
                                              isIgnored: !row.isIgnored,
                                            ),
                                      onAssignmentChanged:
                                          row.rawIngredient == null
                                          ? null
                                          : (selection) {
                                              onAssignmentChanged(
                                                ingredient: row.rawIngredient!,
                                                inventoryItemIds:
                                                    selection.inventoryItemIds,
                                                amountConversion:
                                                    selection.amountConversion,
                                              );
                                            },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _MealTemplateTopBar(
            title: l10n.preparedMealTemplateDetailMatchTitle(template.name),
            height: _topBarContentHeight,
          ),
          if (showFooter)
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _MealTemplateFooter(
                  hasAssignmentChanges: hasAssignmentChanges,
                  isCreatingMeal: isCreatingMeal,
                  isSavingTemplate: isSavingTemplate,
                  canCreateMeal: canCreateMeal,
                  onSaveTemplatePressed: onSaveTemplatePressed,
                  onAddIngredientsToShoppingListPressed:
                      onAddIngredientsToShoppingListPressed,
                  onCreateMealPressed: onCreateMealPressed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealTemplateTopBar extends StatelessWidget {
  const _MealTemplateTopBar({required this.title, required this.height});

  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppInventoryEditorial.glassBlur,
          sigmaY: AppInventoryEditorial.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.34),
            border: Border(
              bottom: BorderSide(
                color: AppInventoryEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppInventoryEditorial.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(AppRoutes.homeInventoryTemplates);
                      },
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceContainerLowest
                            .withValues(alpha: 0.82),
                        foregroundColor: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealTemplateHeroSection extends StatelessWidget {
  const _MealTemplateHeroSection({
    required this.templateName,
    required this.imageBytes,
    required this.imageUrl,
    required this.portionsLabel,
    required this.basePortionsLabel,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
  });

  static const _heroHeight = 252.0;

  final String templateName;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String portionsLabel;
  final String basePortionsLabel;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _heroHeight + 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: _heroHeight,
            child: _MealTemplateHeroImage(
              templateName: templateName,
              imageBytes: imageBytes,
              imageUrl: imageUrl,
            ),
          ),
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: 0,
            child: _MealTemplatePortionCard(
              portionsLabel: portionsLabel,
              basePortionsLabel: basePortionsLabel,
              onDecreasePortions: onDecreasePortions,
              onIncreasePortions: onIncreasePortions,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTemplateHeroImage extends StatelessWidget {
  const _MealTemplateHeroImage({
    required this.templateName,
    required this.imageBytes,
    required this.imageUrl,
  });

  final String templateName;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageBytes != null)
          Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _MealTemplateHeroFallback(templateName: templateName);
            },
          )
        else if (normalizedImageUrl != null)
          AppCachedNetworkImage(
            imageUrl: normalizedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _MealTemplateHeroFallback(templateName: templateName);
            },
          )
        else
          _MealTemplateHeroFallback(templateName: templateName),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.34),
                Colors.black.withValues(alpha: 0.08),
                Color.alphaBlend(
                  colors.surface.withValues(alpha: 0.94),
                  colors.surface,
                ),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTemplateHeroFallback extends StatelessWidget {
  const _MealTemplateHeroFallback({required this.templateName});

  final String templateName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = templateName.trim().isEmpty
        ? '?'
        : templateName.trim().substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerHighest],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MealTemplatePortionCard extends StatelessWidget {
  const _MealTemplatePortionCard({
    required this.portionsLabel,
    required this.basePortionsLabel,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
  });

  final String portionsLabel;
  final String basePortionsLabel;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 28,
            offset: const Offset(0, 14),
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
              color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: radius,
              border: Border.all(
                color: AppInventoryEditorialSurfaces.ghostBorder(
                  colors,
                ).withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _PortionAdjustButton(
                    icon: Icons.remove_rounded,
                    onPressed: onDecreasePortions,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          portionsLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          basePortionsLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _PortionAdjustButton(
                    icon: Icons.add_rounded,
                    onPressed: onIncreasePortions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortionAdjustButton extends StatelessWidget {
  const _PortionAdjustButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerLow,
        foregroundColor: colors.primary,
        disabledBackgroundColor: colors.surfaceContainerHighest,
        disabledForegroundColor: colors.onSurfaceVariant,
      ),
    );
  }
}

class _MealTemplateEmptyIngredientsCard extends StatelessWidget {
  const _MealTemplateEmptyIngredientsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

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
                              label: l10n
                                  .preparedMealTemplateDetailIngredientsToShoppingListAction,
                              onPressed: isSavingTemplate || isCreatingMeal
                                  ? null
                                  : () async {
                                      await onAddIngredientsToShoppingListPressed();
                                    },
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

@visibleForTesting
class MealTemplateFooterTestHarness extends StatelessWidget {
  const MealTemplateFooterTestHarness({
    super.key,
    required this.hasAssignmentChanges,
    required this.isCreatingMeal,
    required this.isSavingTemplate,
    required this.canCreateMeal,
    this.onSaveTemplatePressed,
    this.onAddIngredientsToShoppingListPressed,
    this.onCreateMealPressed,
  });

  final bool hasAssignmentChanges;
  final bool isCreatingMeal;
  final bool isSavingTemplate;
  final bool canCreateMeal;
  final Future<void> Function()? onSaveTemplatePressed;
  final Future<void> Function()? onAddIngredientsToShoppingListPressed;
  final Future<void> Function()? onCreateMealPressed;

  @override
  Widget build(BuildContext context) {
    return _MealTemplateFooter(
      hasAssignmentChanges: hasAssignmentChanges,
      isCreatingMeal: isCreatingMeal,
      isSavingTemplate: isSavingTemplate,
      canCreateMeal: canCreateMeal,
      onSaveTemplatePressed:
          onSaveTemplatePressed ?? () => Future<void>.value(),
      onAddIngredientsToShoppingListPressed:
          onAddIngredientsToShoppingListPressed ?? () => Future<void>.value(),
      onCreateMealPressed: onCreateMealPressed ?? () => Future<void>.value(),
    );
  }
}
