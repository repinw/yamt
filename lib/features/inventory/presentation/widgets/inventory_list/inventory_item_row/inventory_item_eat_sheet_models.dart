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
    required this.label,
    required this.clearTooltip,
    required this.controller,
    required this.focusNode,
    required this.unitLabel,
    required this.errorText,
    required this.selectedAmount,
    required this.quickOptions,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    required this.onQuickOptionSelected,
  });

  final String label;
  final String clearTooltip;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? unitLabel;
  final String? errorText;
  final int? selectedAmount;
  final List<({String label, int value})> quickOptions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;
  final ValueChanged<int> onQuickOptionSelected;
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
  final List<({String label, double amount, ConsumedUnit unit})> suggestions;
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
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final String unitLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
}

class _InventoryItemEatSheetFooterData {
  const _InventoryItemEatSheetFooterData({
    required this.confirmActionText,
    required this.onConfirm,
  });

  final String confirmActionText;
  final VoidCallback onConfirm;
}
