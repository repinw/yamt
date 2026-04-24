import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines serving suggestion resolution.
class ServingSuggestionResolution {
  /// The serving suggestion resolution.
  const ServingSuggestionResolution({
    required this.inventoryServingOptions,
    required this.manualServingSuggestions,
    required this.portionSuggestions,
    required this.inventoryDefaultAmount,
    required this.manualDefaultSuggestion,
    required this.portionDefaultSuggestion,
  });

  /// Inventory amount quick options.
  final List<InventoryServingOption> inventoryServingOptions;

  /// Suggested servings for manual calorie amount input.
  final List<PortionSuggestion> manualServingSuggestions;

  /// Suggested portions for multiplier input.
  final List<PortionSuggestion> portionSuggestions;

  /// The inventory default amount.
  final int? inventoryDefaultAmount;

  /// The default manual serving suggestion.
  final PortionSuggestion? manualDefaultSuggestion;

  /// The default portion suggestion.
  final PortionSuggestion? portionDefaultSuggestion;
}

/// Inventory amount quick option.
class InventoryServingOption {
  /// The inventory serving option.
  const InventoryServingOption({required this.label, required this.value});

  /// User-facing label.
  final String label;

  /// Inventory amount value in the item's storage scale.
  final int value;
}

/// Portion suggestion with display and learning metadata.
class PortionSuggestion {
  /// The portion suggestion.
  const PortionSuggestion({
    required this.label,
    required this.amount,
    required this.unit,
    this.portionLabel,
  });

  /// User-facing suggestion label.
  final String label;

  /// Base amount per portion.
  final double amount;

  /// Unit for [amount].
  final ConsumedUnit unit;

  /// User-facing portion name, for example "slice" or "can".
  final String? portionLabel;
}

class _InventoryServingCandidate {
  const _InventoryServingCandidate({
    required this.label,
    required this.amount,
    required this.unit,
    this.portionLabel,
  });

  final String label;
  final double amount;
  final InventoryAmountUnit unit;
  final String? portionLabel;
}

class _ServingAmount {
  const _ServingAmount({required this.amount, required this.unit});

  final double amount;
  final InventoryAmountUnit unit;
}

/// Defines serving suggestion resolver.
class ServingSuggestionResolver {
  /// The serving suggestion resolver.
  const ServingSuggestionResolver();

  static const _servingAmountParser = InventoryAmountParser();

  /// Resolve.
  ServingSuggestionResolution resolve({
    required InventoryItem item,
    required GlobalFoodServingSuggestionSet learned,
    required int maxAmount,
    required bool requiresManualPortion,
  }) {
    final inventoryServingSuggestions = _inventoryServingSuggestions(
      item: item,
      learned: learned,
      maxAmount: maxAmount,
    );
    final portionSuggestions = _portionServingSuggestions(
      item: item,
      learned: learned,
    );
    final manualServingSuggestions = requiresManualPortion
        ? portionSuggestions
        : const <PortionSuggestion>[];

    final inventoryDefault = _resolveInventoryDefault(
      item: item,
      learned: learned,
      maxAmount: maxAmount,
    );
    final manualDefault = _resolveManualDefault(
      learned: learned,
      requiresManualPortion: requiresManualPortion,
    );
    final portionDefault = _resolvePortionDefault(item: item, learned: learned);

    return ServingSuggestionResolution(
      inventoryServingOptions: inventoryServingSuggestions,
      manualServingSuggestions: manualServingSuggestions,
      portionSuggestions: portionSuggestions,
      inventoryDefaultAmount: inventoryDefault,
      manualDefaultSuggestion: manualDefault,
      portionDefaultSuggestion: portionDefault,
    );
  }

  int? _resolveInventoryDefault({
    required InventoryItem item,
    required GlobalFoodServingSuggestionSet learned,
    required int maxAmount,
  }) {
    final suggestion = learned.defaultSuggestion;
    if (suggestion == null || !item.usesAmountProgress) {
      return null;
    }

    final inventoryUnit = _inventoryUnitForConsumedUnit(suggestion.unit);
    if (inventoryUnit != item.amountUnit ||
        !_isWholeNumber(suggestion.amount)) {
      return null;
    }

    final value = suggestion.amount.round();
    if (value < 1 || value > maxAmount) {
      return null;
    }
    return value;
  }

  PortionSuggestion? _resolveManualDefault({
    required GlobalFoodServingSuggestionSet learned,
    required bool requiresManualPortion,
  }) {
    if (!requiresManualPortion) {
      return null;
    }
    final suggestion = learned.defaultSuggestion;
    if (suggestion == null) {
      return null;
    }
    return PortionSuggestion(
      label: _formatLearnedServingLabel(
        amount: suggestion.amount,
        unit: suggestion.unit,
        portionLabel: suggestion.label,
      ),
      amount: suggestion.amount,
      unit: suggestion.unit,
      portionLabel: suggestion.label,
    );
  }

  PortionSuggestion? _resolvePortionDefault({
    required InventoryItem item,
    required GlobalFoodServingSuggestionSet learned,
  }) {
    final learnedSuggestion = learned.defaultSuggestion;
    if (learnedSuggestion != null &&
        _canUsePortionSuggestionForItem(item, learnedSuggestion.unit)) {
      return PortionSuggestion(
        label: _formatLearnedServingLabel(
          amount: learnedSuggestion.amount,
          unit: learnedSuggestion.unit,
          portionLabel: learnedSuggestion.label,
        ),
        amount: learnedSuggestion.amount,
        unit: learnedSuggestion.unit,
        portionLabel: learnedSuggestion.label,
      );
    }

    final structured = _resolvedServingSuggestion(item);
    if (structured == null) {
      return null;
    }
    final unit = _consumedUnitForInventoryUnit(structured.unit);
    if (unit == null) {
      return null;
    }
    return PortionSuggestion(
      label: structured.label,
      amount: structured.amount,
      unit: unit,
      portionLabel: structured.portionLabel,
    );
  }

  List<InventoryServingOption> _inventoryServingSuggestions({
    required InventoryItem item,
    required GlobalFoodServingSuggestionSet learned,
    required int maxAmount,
  }) {
    if (!item.usesAmountProgress || item.amountUnit == null) {
      return const <InventoryServingOption>[];
    }

    final options = <InventoryServingOption>[];
    final seenValues = <int>{};

    for (final suggestion in _buildLearnedInventoryServingSuggestions(
      learned: learned,
    )) {
      if (suggestion.unit != item.amountUnit ||
          !_isWholeNumber(suggestion.amount)) {
        continue;
      }

      final value = suggestion.amount.round();
      if (value < 1 || value > maxAmount || !seenValues.add(value)) {
        continue;
      }
      options.add(
        InventoryServingOption(label: suggestion.label, value: value),
      );
    }

    final structured = _resolvedServingSuggestion(item);
    if (structured != null &&
        structured.unit == item.amountUnit &&
        _isWholeNumber(structured.amount)) {
      final value = structured.amount.round();
      if (value >= 1 && value <= maxAmount && seenValues.add(value)) {
        options.add(
          InventoryServingOption(label: structured.label, value: value),
        );
      }
    }

    return options;
  }

  List<PortionSuggestion> _portionServingSuggestions({
    required InventoryItem item,
    required GlobalFoodServingSuggestionSet learned,
  }) {
    final suggestions = <PortionSuggestion>[];
    final seenKeys = <String>{};

    final personal = learned.personalSuggestion;
    if (personal != null &&
        _canUsePortionSuggestionForItem(item, personal.unit)) {
      final key = _manualSuggestionKey(
        amount: personal.amount,
        unit: personal.unit,
      );
      if (seenKeys.add(key)) {
        suggestions.add(
          PortionSuggestion(
            label: _formatLearnedServingLabel(
              amount: personal.amount,
              unit: personal.unit,
              portionLabel: personal.label,
            ),
            amount: personal.amount,
            unit: personal.unit,
            portionLabel: personal.label,
          ),
        );
      }
    }

    for (final suggestion in learned.globalSuggestions) {
      if (!_canUsePortionSuggestionForItem(item, suggestion.unit)) {
        continue;
      }
      final key = _manualSuggestionKey(
        amount: suggestion.amount,
        unit: suggestion.unit,
      );
      if (!seenKeys.add(key)) {
        continue;
      }
      suggestions.add(
        PortionSuggestion(
          label: _formatLearnedServingLabel(
            amount: suggestion.amount,
            unit: suggestion.unit,
            portionLabel: suggestion.label,
          ),
          amount: suggestion.amount,
          unit: suggestion.unit,
          portionLabel: suggestion.label,
        ),
      );
    }

    final structured = _resolvedServingSuggestion(item);
    if (structured != null) {
      final consumedUnit = _consumedUnitForInventoryUnit(structured.unit);
      if (consumedUnit != null &&
          _canUsePortionSuggestionForItem(item, consumedUnit)) {
        final key = _manualSuggestionKey(
          amount: structured.amount,
          unit: consumedUnit,
        );
        if (seenKeys.add(key)) {
          suggestions.add(
            PortionSuggestion(
              label: structured.label,
              amount: structured.amount,
              unit: consumedUnit,
              portionLabel: structured.portionLabel,
            ),
          );
        }
      }
    }

    return suggestions.take(5).toList(growable: false);
  }

  List<_InventoryServingCandidate> _buildLearnedInventoryServingSuggestions({
    required GlobalFoodServingSuggestionSet learned,
  }) {
    final suggestions = <_InventoryServingCandidate>[];
    final personal = learned.personalSuggestion;
    if (personal != null) {
      final inventoryUnit = _inventoryUnitForConsumedUnit(personal.unit);
      if (inventoryUnit != null) {
        suggestions.add(
          _InventoryServingCandidate(
            label: _formatLearnedServingLabel(
              amount: personal.amount,
              unit: personal.unit,
              portionLabel: personal.label,
            ),
            amount: personal.amount,
            unit: inventoryUnit,
            portionLabel: personal.label,
          ),
        );
      }
    }

    for (final suggestion in learned.globalSuggestions) {
      final inventoryUnit = _inventoryUnitForConsumedUnit(suggestion.unit);
      if (inventoryUnit == null) {
        continue;
      }
      suggestions.add(
        _InventoryServingCandidate(
          label: _formatLearnedServingLabel(
            amount: suggestion.amount,
            unit: suggestion.unit,
            portionLabel: suggestion.label,
          ),
          amount: suggestion.amount,
          unit: inventoryUnit,
          portionLabel: suggestion.label,
        ),
      );
    }
    return suggestions;
  }

  _InventoryServingCandidate? _resolvedServingSuggestion(InventoryItem item) {
    final structuredSuggestion = _suggestionFromStructuredServing(item);
    if (structuredSuggestion != null &&
        !_matchesPackageWeight(item, structuredSuggestion)) {
      return structuredSuggestion;
    }

    final servingSize = item.servingSize;
    if (servingSize == null) {
      return null;
    }

    final parsed = _servingAmountParser.tryParse(
      rawWeight: servingSize,
      quantity: 1,
    );
    if (parsed == null || parsed.amount < 1) {
      return null;
    }

    final suggestion = _InventoryServingCandidate(
      label: servingSize,
      amount: parsed.amount.toDouble(),
      unit: parsed.unit,
      portionLabel: _derivePortionLabel(servingSize),
    );
    if (_matchesPackageWeight(item, suggestion)) {
      return null;
    }
    return suggestion;
  }

  _InventoryServingCandidate? _suggestionFromStructuredServing(
    InventoryItem item,
  ) {
    final quantity = item.servingQuantity;
    final unit = item.servingQuantityUnit;
    if (quantity == null || unit == null || quantity <= 0) {
      return null;
    }

    final normalizedUnit = unit.trim().toLowerCase();
    final converted = switch (normalizedUnit) {
      'g' || 'gr' || 'gram' || 'grams' => _ServingAmount(
        amount: quantity,
        unit: InventoryAmountUnit.gram,
      ),
      'kg' || 'kilogram' || 'kilograms' => _ServingAmount(
        amount: quantity * 1000,
        unit: InventoryAmountUnit.gram,
      ),
      'mg' => _ServingAmount(
        amount: quantity / 1000,
        unit: InventoryAmountUnit.gram,
      ),
      'ml' => _ServingAmount(
        amount: quantity,
        unit: InventoryAmountUnit.milliliter,
      ),
      'cl' => _ServingAmount(
        amount: quantity * 10,
        unit: InventoryAmountUnit.milliliter,
      ),
      'dl' => _ServingAmount(
        amount: quantity * 100,
        unit: InventoryAmountUnit.milliliter,
      ),
      'l' || 'liter' || 'liters' || 'litre' || 'litres' => _ServingAmount(
        amount: quantity * 1000,
        unit: InventoryAmountUnit.milliliter,
      ),
      'pc' || 'piece' || 'pieces' || 'st' || 'stk' => _ServingAmount(
        amount: quantity * inventoryPieceAmountScale,
        unit: InventoryAmountUnit.piece,
      ),
      _ => null,
    };
    if (converted == null || converted.amount <= 0) {
      return null;
    }

    return _InventoryServingCandidate(
      label: item.servingSize ?? _formatServingLabel(converted),
      amount: converted.amount,
      unit: converted.unit,
      portionLabel: _derivePortionLabel(item.servingSize),
    );
  }

  bool _matchesPackageWeight(
    InventoryItem item,
    _InventoryServingCandidate suggestion,
  ) {
    final weight = item.weight;
    if (weight == null) {
      return false;
    }

    final parsedWeight = _servingAmountParser.tryParse(
      rawWeight: weight,
      quantity: 1,
    );
    if (parsedWeight != null &&
        parsedWeight.unit == suggestion.unit &&
        parsedWeight.amount.toDouble() == suggestion.amount) {
      return true;
    }

    final normalizedWeight = _normalizeComparableAmountText(weight);
    final normalizedServing = _normalizeComparableAmountText(suggestion.label);
    return normalizedWeight.isNotEmpty && normalizedWeight == normalizedServing;
  }

  String _formatServingLabel(_ServingAmount serving) {
    final code = serving.unit.code;
    final value = serving.unit == InventoryAmountUnit.piece
        ? formatInventoryAmountValue(
            amount: serving.amount.round(),
            unit: serving.unit,
            scale: inventoryPieceAmountScale,
          )
        : _formatInventoryNutritionValue(serving.amount);
    return code.isEmpty ? value : '$value $code';
  }

  String _formatLearnedServingLabel({
    required double amount,
    required ConsumedUnit unit,
    String? portionLabel,
  }) {
    final amountLabel =
        '${_formatInventoryNutritionValue(amount)} ${unit.jsonValue}';
    final normalizedLabel = portionLabel?.trim();
    if (normalizedLabel == null || normalizedLabel.isEmpty) {
      return amountLabel;
    }
    return '$normalizedLabel - $amountLabel';
  }

  String _normalizeComparableAmountText(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isWholeNumber(double value) {
    return value == value.roundToDouble();
  }

  InventoryAmountUnit? _inventoryUnitForConsumedUnit(ConsumedUnit unit) {
    return switch (unit) {
      ConsumedUnit.grams => InventoryAmountUnit.gram,
      ConsumedUnit.milliliters => InventoryAmountUnit.milliliter,
    };
  }

  bool _canUsePortionSuggestionForItem(
    InventoryItem item,
    ConsumedUnit unit,
  ) {
    if (!item.usesAmountProgress) {
      return true;
    }
    final inventoryUnit = _inventoryUnitForConsumedUnit(unit);
    return inventoryUnit == item.amountUnit ||
        item.amountUnit == InventoryAmountUnit.piece;
  }

  ConsumedUnit? _consumedUnitForInventoryUnit(InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => ConsumedUnit.grams,
      InventoryAmountUnit.milliliter => ConsumedUnit.milliliters,
      InventoryAmountUnit.piece => null,
    };
  }

  String? _derivePortionLabel(String? servingSize) {
    final raw = servingSize?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final withoutParentheses = raw
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withoutLeadingCount = withoutParentheses
        .replaceFirst(RegExp(r'^\d+(?:[.,]\d+)?\s*(?:x|X)?\s*'), '')
        .trim();
    if (withoutLeadingCount.isEmpty ||
        withoutLeadingCount.contains(RegExp(r'\d'))) {
      return null;
    }
    if (!withoutLeadingCount.contains(RegExp('[A-Za-zÀ-ÖØ-öø-ÿ]'))) {
      return null;
    }

    final normalized = withoutLeadingCount.toLowerCase();
    const amountUnits = <String>{
      'g',
      'gr',
      'gram',
      'grams',
      'kg',
      'mg',
      'ml',
      'cl',
      'dl',
      'l',
      'liter',
      'liters',
      'litre',
      'litres',
    };
    if (amountUnits.contains(normalized)) {
      return null;
    }
    return withoutLeadingCount;
  }

  String _manualSuggestionKey({
    required double amount,
    required ConsumedUnit unit,
  }) {
    return '${unit.jsonValue}:${buildServingSuggestionAmountKey(amount)}';
  }

  String _formatInventoryNutritionValue(double value) {
    final hasFraction = value % 1 != 0;
    return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  }
}
