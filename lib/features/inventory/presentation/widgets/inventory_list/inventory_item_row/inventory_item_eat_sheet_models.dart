part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSheetViewData {
  const _InventoryItemEatSheetViewData({
    required this.viewInsetsBottom,
    required this.hero,
    required this.amountSection,
    required this.manualPortionSection,
    required this.nutritionMetrics,
    required this.whenSection,
    required this.inedibleSection,
    required this.footer,
  });

  final double viewInsetsBottom;
  final _InventoryItemEatSheetHeroData hero;
  final _InventoryItemEatSheetAmountSectionData amountSection;
  final _InventoryItemEatSheetManualPortionSectionData? manualPortionSection;
  final List<({String label, String value})> nutritionMetrics;
  final _InventoryItemEatSheetWhenSectionData whenSection;
  final _InventoryItemEatSheetInedibleSectionData? inedibleSection;
  final _InventoryItemEatSheetFooterData footer;
}

class _InventoryItemEatSheetHeroData {
  const _InventoryItemEatSheetHeroData({
    required this.itemName,
    required this.imageUrl,
    required this.eyebrow,
  });

  final String itemName;
  final String? imageUrl;
  final String eyebrow;
}

class _InventoryItemEatSheetAmountSectionData {
  const _InventoryItemEatSheetAmountSectionData({
    required this.clearTooltip,
    required this.controller,
    required this.focusNode,
    required this.modeOptions,
    required this.selectedModeId,
    required this.totalLabel,
    required this.errorText,
    required this.selectedAmount,
    required this.allowFractionalInput,
    required this.quickOptions,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    required this.onQuickOptionSelected,
    required this.onModeSelected,
  });

  final String clearTooltip;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_InventoryItemEatAmountModeOption> modeOptions;
  final String selectedModeId;
  final String? totalLabel;
  final String? errorText;
  final int? selectedAmount;
  final bool allowFractionalInput;
  final List<({String label, int value})> quickOptions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;
  final ValueChanged<int> onQuickOptionSelected;
  final ValueChanged<String> onModeSelected;
}

class _InventoryItemEatAmountModeOption {
  const _InventoryItemEatAmountModeOption({
    required this.id,
    required this.label,
    this.amount,
    this.unit,
    this.portionLabel,
    this.isNewPortion = false,
  });

  final String id;
  final String label;
  final double? amount;
  final ConsumedUnit? unit;
  final String? portionLabel;
  final bool isNewPortion;

  bool get isPortion {
    return amount != null && unit != null && !isNewPortion;
  }
}

class _InventoryItemEatSheetManualPortionSectionData {
  const _InventoryItemEatSheetManualPortionSectionData({
    required this.title,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.selectedUnit,
    required this.suggestions,
    required this.onAmountChanged,
    required this.onUnitChanged,
    required this.onSubmitted,
    required this.onSuggestionPressed,
  });

  final String title;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ConsumedUnit selectedUnit;
  final List<
    ({String label, double amount, ConsumedUnit unit, String? portionLabel})
  >
  suggestions;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<ConsumedUnit> onUnitChanged;
  final VoidCallback onSubmitted;
  final void Function({required double amount, required ConsumedUnit unit})
  onSuggestionPressed;
}

class _InventoryItemEatSheetWhenSectionData {
  const _InventoryItemEatSheetWhenSectionData({
    required this.isToday,
    required this.label,
    required this.selectedMealType,
    required this.onPickLoggedAt,
    required this.onMealTypeSelected,
  });

  final bool isToday;
  final String? label;
  final MealType selectedMealType;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeSelected;
}

class _InventoryItemEatSheetInedibleSectionData {
  const _InventoryItemEatSheetInedibleSectionData({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.unitLabel,
    required this.summaryText,
    required this.isExpanded,
    required this.onChanged,
    required this.onSubmitted,
    required this.onToggleExpanded,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final String unitLabel;
  final String summaryText;
  final bool isExpanded;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onToggleExpanded;
}

class _InventoryItemEatSheetFooterData {
  const _InventoryItemEatSheetFooterData({
    required this.confirmActionText,
    required this.onConfirm,
  });

  final String confirmActionText;
  final VoidCallback onConfirm;
}
