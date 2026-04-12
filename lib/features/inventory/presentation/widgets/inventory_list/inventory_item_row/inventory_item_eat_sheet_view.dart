part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSheetView extends StatelessWidget {
  const _InventoryItemEatSheetView({
    required this.itemName,
    required this.imageUrl,
    required this.eyebrow,
    required this.viewInsetsBottom,
    required this.amountLabel,
    required this.clearAmountTooltip,
    required this.inventoryAmountController,
    required this.inventoryAmountFocusNode,
    required this.unitLabel,
    required this.inventoryAmountErrorText,
    required this.onInventoryAmountChanged,
    required this.onInventoryAmountClearAndFocus,
    required this.onDismissKeyboard,
    required this.quickOptions,
    required this.selectedAmount,
    required this.onInventoryQuickOptionSelected,
    required this.requiresManualCaloriePortion,
    required this.manualPortionTitle,
    required this.manualCalorieAmountController,
    required this.manualCalorieAmountFocusNode,
    required this.manualCalorieAmountErrorText,
    required this.selectedManualCalorieUnit,
    required this.onManualCalorieAmountChanged,
    required this.onManualCalorieUnitChanged,
    required this.manualServingSuggestions,
    required this.onManualServingSuggestionPressed,
    required this.nutritionMetrics,
    required this.loggedAtLabel,
    required this.onPickLoggedAt,
    required this.selectedMealType,
    required this.onMealTypeSelected,
    required this.supportsInedibleAmountAdjustment,
    required this.inedibleAmountController,
    required this.inedibleAmountFocusNode,
    required this.inedibleAmountErrorText,
    required this.onInedibleAmountChanged,
    required this.inedibleAmountUnitLabel,
    required this.confirmActionText,
    required this.onConfirm,
  });

  final String itemName;
  final String? imageUrl;
  final String eyebrow;
  final double viewInsetsBottom;
  final String amountLabel;
  final String clearAmountTooltip;
  final TextEditingController inventoryAmountController;
  final FocusNode inventoryAmountFocusNode;
  final String? unitLabel;
  final String? inventoryAmountErrorText;
  final ValueChanged<String> onInventoryAmountChanged;
  final VoidCallback onInventoryAmountClearAndFocus;
  final VoidCallback onDismissKeyboard;
  final List<({String label, int value})> quickOptions;
  final int? selectedAmount;
  final ValueChanged<int> onInventoryQuickOptionSelected;
  final bool requiresManualCaloriePortion;
  final String manualPortionTitle;
  final TextEditingController manualCalorieAmountController;
  final FocusNode manualCalorieAmountFocusNode;
  final String? manualCalorieAmountErrorText;
  final ConsumedUnit selectedManualCalorieUnit;
  final ValueChanged<String> onManualCalorieAmountChanged;
  final ValueChanged<ConsumedUnit> onManualCalorieUnitChanged;
  final List<({String label, double amount, ConsumedUnit unit})>
  manualServingSuggestions;
  final void Function({required double amount, required ConsumedUnit unit})
  onManualServingSuggestionPressed;
  final List<({String label, String value})> nutritionMetrics;
  final String loggedAtLabel;
  final VoidCallback onPickLoggedAt;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeSelected;
  final bool supportsInedibleAmountAdjustment;
  final TextEditingController inedibleAmountController;
  final FocusNode inedibleAmountFocusNode;
  final String? inedibleAmountErrorText;
  final ValueChanged<String> onInedibleAmountChanged;
  final String inedibleAmountUnitLabel;
  final String confirmActionText;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: viewInsetsBottom + AppSpacing.xxxl,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppInventoryEditorial.cardRadius,
              ),
              child: DecoratedBox(
                decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
                  colors,
                  borderRadius: BorderRadius.circular(
                    AppInventoryEditorial.cardRadius,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InventoryItemEatHero(
                              itemName: itemName,
                              eyebrow: eyebrow,
                              imageUrl: imageUrl,
                            ),
                            Padding(
                              padding: AppInsets.card,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _InventoryItemEatSectionCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _InventoryItemEatCardTitle(
                                          text: amountLabel,
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        _InventoryItemEatAmountCard(
                                          controller: inventoryAmountController,
                                          focusNode: inventoryAmountFocusNode,
                                          unitLabel: unitLabel,
                                          errorText: inventoryAmountErrorText,
                                          clearTooltip: clearAmountTooltip,
                                          onChanged: onInventoryAmountChanged,
                                          onClearAndFocus:
                                              onInventoryAmountClearAndFocus,
                                          onSubmitted: onDismissKeyboard,
                                        ),
                                        if (quickOptions.isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.lg),
                                          _InventoryItemEatQuickChipScroller(
                                            children: [
                                              for (final option in quickOptions)
                                                _InventoryItemEatQuickChip(
                                                  label: option.label,
                                                  isSelected:
                                                      selectedAmount ==
                                                      option.value,
                                                  onPressed: () =>
                                                      onInventoryQuickOptionSelected(
                                                        option.value,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (requiresManualCaloriePortion) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _InventoryItemEatSectionCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _InventoryItemEatCardTitle(
                                            text: manualPortionTitle,
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          _InventoryItemEatManualPortionSection(
                                            amountController:
                                                manualCalorieAmountController,
                                            amountFocusNode:
                                                manualCalorieAmountFocusNode,
                                            amountErrorText:
                                                manualCalorieAmountErrorText,
                                            selectedUnit:
                                                selectedManualCalorieUnit,
                                            onAmountChanged:
                                                onManualCalorieAmountChanged,
                                            onUnitChanged:
                                                onManualCalorieUnitChanged,
                                            onSubmitted: onDismissKeyboard,
                                          ),
                                          if (manualServingSuggestions
                                              .isNotEmpty) ...[
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _InventoryItemEatQuickChipScroller(
                                              children: [
                                                for (final suggestion
                                                    in manualServingSuggestions)
                                                  _InventoryItemEatQuickChip(
                                                    label: suggestion.label,
                                                    isSelected:
                                                        selectedManualCalorieUnit ==
                                                            suggestion.unit &&
                                                        manualCalorieAmountController
                                                                .text
                                                                .trim() ==
                                                            formatInventoryNutritionValue(
                                                              suggestion.amount,
                                                            ),
                                                    onPressed: () =>
                                                        onManualServingSuggestionPressed(
                                                          amount:
                                                              suggestion.amount,
                                                          unit: suggestion.unit,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (nutritionMetrics.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _InventoryItemEatSectionCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xl,
                                        vertical: AppSpacing.xl,
                                      ),
                                      child:
                                          _InventoryItemEatNutritionMetricsRow(
                                            metrics: nutritionMetrics,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xxxl),
                                  Row(
                                    children: [
                                      if (loggedAtLabel.isEmpty)
                                        _InventoryItemEatWhenCard(
                                          label: loggedAtLabel,
                                          onPressed: onPickLoggedAt,
                                        )
                                      else
                                        Expanded(
                                          child: _InventoryItemEatWhenCard(
                                            label: loggedAtLabel,
                                            onPressed: onPickLoggedAt,
                                          ),
                                        ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child:
                                            _InventoryItemEatMealTypeSelector(
                                              selectedMealType:
                                                  selectedMealType,
                                              onMealTypeSelected:
                                                  onMealTypeSelected,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (supportsInedibleAmountAdjustment) ...[
                                    const SizedBox(height: AppSpacing.xxxl),
                                    _InventoryItemEatInedibleAmountSection(
                                      amountController:
                                          inedibleAmountController,
                                      amountFocusNode: inedibleAmountFocusNode,
                                      amountErrorText: inedibleAmountErrorText,
                                      unitLabel: inedibleAmountUnitLabel,
                                      onAmountChanged: onInedibleAmountChanged,
                                      onSubmitted: onDismissKeyboard,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        border: Border(
                          top: BorderSide(
                            color: AppInventoryEditorialSurfaces.ghostBorder(
                              colors,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key(
                              'inventory_item_amount_dialog_confirm_button',
                            ),
                            onPressed: onConfirm,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xxl,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                              ),
                              backgroundColor: colors.primary,
                            ),
                            child: Text(
                              confirmActionText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
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
