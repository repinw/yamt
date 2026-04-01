import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/inventory/provider/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/shoppinglist/provider/'
    'shopping_list_controller.dart';

class MealTemplateDetailPage extends ConsumerStatefulWidget {
  const MealTemplateDetailPage({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<MealTemplateDetailPage> createState() =>
      _MealTemplateDetailPageState();
}

class _MealTemplateDetailPageState
    extends ConsumerState<MealTemplateDetailPage> {
  int? _selectedPortions;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        // TODO(l10n): Localize meal template detail texts.
        title: const Text('Vorlage'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          final template = _findTemplate(
            templates: templates,
            templateId: widget.templateId,
          );
          if (template == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Vorlage nicht gefunden.'),
              ),
            );
          }

          final selectedPortions =
              _selectedPortions ?? _defaultPortions(template.totalPortions);
          return _MealTemplateDetailContent(
            template: template,
            selectedPortions: selectedPortions,
            onDecreasePortions: selectedPortions > 1
                ? () {
                    setState(() {
                      _selectedPortions = selectedPortions - 1;
                    });
                  }
                : null,
            onIncreasePortions: () {
              setState(() {
                _selectedPortions = selectedPortions + 1;
              });
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Vorlage konnte nicht geladen werden.'),
            ),
          );
        },
      ),
    );
  }
}

class _MealTemplateDetailContent extends ConsumerWidget {
  const _MealTemplateDetailContent({
    required this.template,
    required this.selectedPortions,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
  });

  final PreparedMeal template;
  final int selectedPortions;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final inventoryItems =
        ref.watch(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final recipeSourceHost = _recipeSourceHost(template.recipeUrl);
    final ingredientRows = _buildIngredientRows(
      template: template,
      selectedPortions: selectedPortions,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreparedMealCover(
              label: template.name,
              imageBytes: storedImageBytes,
              imageUrl: template.imageUrl,
              size: 112,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recipeSourceHost != null)
                    Text(
                      'Quelle: $recipeSourceHost',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Basis-Portionen: ${template.totalPortions}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: AppInsets.card,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portionen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Zutaten werden auf diese Portionszahl skaliert.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDecreasePortions,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$selectedPortions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: onIncreasePortions,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Zutaten', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (ingredientRows.isEmpty)
          const Text('Noch keine Zutaten vorhanden.')
        else
          Column(
            children: [
              for (final row in ingredientRows) ...[
                _MealTemplateIngredientCard(
                  templateId: template.id,
                  row: row,
                  inventoryItems: inventoryItems,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
      ],
    );
  }
}

class _MealTemplateIngredientCard extends ConsumerStatefulWidget {
  const _MealTemplateIngredientCard({
    required this.templateId,
    required this.row,
    required this.inventoryItems,
  });

  final String templateId;
  final _IngredientRowData row;
  final List<InventoryItem> inventoryItems;

  @override
  ConsumerState<_MealTemplateIngredientCard> createState() =>
      _MealTemplateIngredientCardState();
}

class _MealTemplateIngredientCardState
    extends ConsumerState<_MealTemplateIngredientCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final assignedItems = _resolveAssignedItems(
      inventoryItemIds: widget.row.assignedInventoryItemIds,
      inventoryItems: widget.inventoryItems,
    );
    final missingAssignedCount =
        widget.row.assignedInventoryItemIds.length - assignedItems.length;
    final suggestions = widget.row.isIgnored
        ? const <InventoryItem>[]
        : _matchingInventoryItems(
            ingredientName: widget.row.name,
            inventoryItems: widget.inventoryItems,
          ).take(3).toList(growable: false);
    final previewImageUrl = _resolvePreviewImageUrl(
      assignedItems: assignedItems,
      suggestions: suggestions,
    );
    final subtitle = _buildIngredientSubtitle(
      row: widget.row,
      assignedItems: assignedItems,
    );

    final ingredientStyle = widget.row.isIgnored
        ? textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: colors.onSurfaceVariant,
          )
        : textTheme.titleMedium;
    final amountStyle = widget.row.isIgnored
        ? textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)
        : textTheme.bodyMedium;

    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _IngredientPreviewThumbnail(imageUrl: previewImageUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.row.name, style: ingredientStyle),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(subtitle, style: amountStyle),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: widget.inventoryItems.isEmpty
                          ? null
                          : () => _selectInventoryAssignments(
                                context: context,
                                ref: ref,
                              templateId: widget.templateId,
                              row: widget.row,
                                inventoryItems: widget.inventoryItems,
                              ),
                      // TODO(l10n): Localize assignment button tooltip.
                      tooltip: widget.row.assignedInventoryItemIds.isEmpty
                          ? 'Zuordnen'
                          : 'Zuordnung ändern',
                      icon: const Icon(Icons.sync_alt_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSpacing.md),
              if (assignedItems.isNotEmpty) ...[
                Text('Aus dem Inventar belegt', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: assignedItems
                      .map(
                        (item) => Chip(
                          label: Text(
                            '${item.name} • '
                            '${_inventoryAmountLabel(item)}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ] else if (suggestions.isNotEmpty) ...[
                Text('Passende Inventarartikel', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  suggestions.map((item) => item.name).join(', '),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (missingAssignedCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$missingAssignedCount belegte Artikel '
                  'sind nicht mehr im Inventar.',
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ],
              if (widget.row.rawIngredient != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.row.isIgnored
                          ? null
                          : () => _addIngredientToShoppingList(
                              context: context,
                              ref: ref,
                              shoppingListLabel: _shoppingListLabel(widget.row),
                            ),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Zur Einkaufsliste'),
                    ),
                    TextButton(
                      onPressed: () => _toggleIgnored(
                        context: context,
                        ref: ref,
                        templateId: widget.templateId,
                        ingredient: widget.row.rawIngredient!,
                        isIgnored: !widget.row.isIgnored,
                      ),
                      child: Text(
                        widget.row.isIgnored
                            ? 'Nicht ignorieren'
                            : 'Ignorieren',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IngredientRowData {
  const _IngredientRowData({
    required this.name,
    required this.amountLabel,
    this.rawIngredient,
    this.canToggleIgnore = false,
    this.isIgnored = false,
    this.assignedInventoryItemIds = const <String>[],
  });

  final String name;
  final String amountLabel;
  final String? rawIngredient;
  final bool canToggleIgnore;
  final bool isIgnored;
  final List<String> assignedInventoryItemIds;
}

class _IngredientPreviewThumbnail extends StatelessWidget {
  const _IngredientPreviewThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 48,
        child: normalizedImageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

PreparedMeal? _findTemplate({
  required List<PreparedMeal> templates,
  required String templateId,
}) {
  for (final template in templates) {
    if (template.id == templateId) {
      return template;
    }
  }
  return null;
}

int _defaultPortions(int totalPortions) {
  return totalPortions > 0 ? totalPortions : 1;
}

List<_IngredientRowData> _buildIngredientRows({
  required PreparedMeal template,
  required int selectedPortions,
}) {
  if (template.components.isNotEmpty) {
    return template.components
        .map(
          (component) => _IngredientRowData(
            name: component.name,
            amountLabel: _scaledComponentAmount(
              component: component,
              selectedPortions: selectedPortions,
              basePortions: template.totalPortions,
            ),
          ),
        )
        .toList(growable: false);
  }

  return template.recipeIngredients
      .map(
        (ingredient) => _scaledRecipeIngredient(
          ingredient,
          isIgnored: template.ignoredRecipeIngredients.contains(ingredient),
          assignedInventoryItemIds:
              template.recipeIngredientAssignments[ingredient] ??
              const <String>[],
          selectedPortions: selectedPortions,
          basePortions: template.totalPortions,
        ),
      )
      .toList(growable: false);
}

_IngredientRowData _scaledRecipeIngredient(
  String ingredient, {
  required bool isIgnored,
  required List<String> assignedInventoryItemIds,
  required int selectedPortions,
  required int basePortions,
}) {
  final trimmed = ingredient.trim();
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(\S+)\s+(.+)$',
  ).firstMatch(trimmed);
  if (match == null) {
    return _IngredientRowData(
      name: trimmed,
      amountLabel: '-',
      rawIngredient: ingredient,
      canToggleIgnore: true,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final rawQuantity = match.group(1);
  final unit = match.group(2);
  final name = match.group(3);
  if (rawQuantity == null || unit == null || name == null) {
    return _IngredientRowData(
      name: trimmed,
      amountLabel: '-',
      rawIngredient: ingredient,
      canToggleIgnore: true,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final parsedQuantity = double.tryParse(rawQuantity.replaceAll(',', '.'));
  if (parsedQuantity == null || basePortions <= 0) {
    return _IngredientRowData(
      name: name,
      amountLabel: '$rawQuantity $unit',
      rawIngredient: ingredient,
      canToggleIgnore: true,
      isIgnored: isIgnored,
      assignedInventoryItemIds: assignedInventoryItemIds,
    );
  }

  final scaledQuantity = parsedQuantity * selectedPortions / basePortions;
  return _IngredientRowData(
    name: name,
    amountLabel: '${_formatAmount(scaledQuantity)} $unit',
    rawIngredient: ingredient,
    canToggleIgnore: true,
    isIgnored: isIgnored,
    assignedInventoryItemIds: assignedInventoryItemIds,
  );
}

String _scaledComponentAmount({
  required PreparedMealComponent component,
  required int selectedPortions,
  required int basePortions,
}) {
  if (basePortions <= 0) {
    return '${component.usedAmount} ${component.usedUnit.code}';
  }

  final scaledAmount = component.usedAmount * selectedPortions / basePortions;
  return '${_formatAmount(scaledAmount)} ${component.usedUnit.code}';
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String? _recipeSourceHost(String? recipeUrl) {
  if (recipeUrl == null || recipeUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(recipeUrl);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  return uri.host.replaceFirst(RegExp(r'^www\.'), '');
}

String _inventoryAmountLabel(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

List<InventoryItem> _resolveAssignedItems({
  required List<String> inventoryItemIds,
  required List<InventoryItem> inventoryItems,
}) {
  if (inventoryItemIds.isEmpty || inventoryItems.isEmpty) {
    return const <InventoryItem>[];
  }

  final itemsById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  return inventoryItemIds
      .map((itemId) => itemsById[itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
}

List<InventoryItem> _matchingInventoryItems({
  required String ingredientName,
  required List<InventoryItem> inventoryItems,
}) {
  final candidates = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return const <InventoryItem>[];
  }

  final sortedCandidates = List<InventoryItem>.from(candidates);
  sortedCandidates.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredientName: ingredientName,
      item: right,
    );
    final leftScore = _ingredientMatchScore(
      ingredientName: ingredientName,
      item: left,
    );
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return sortedCandidates
      .where(
        (item) =>
            _ingredientMatchScore(ingredientName: ingredientName, item: item) >
            0,
      )
      .toList(growable: false);
}

int _ingredientMatchScore({
  required String ingredientName,
  required InventoryItem item,
}) {
  final normalizedIngredient = _normalizeMatchText(ingredientName);
  final normalizedItem = _normalizeMatchText(
    '${item.name} ${item.brand ?? ''}',
  );
  if (normalizedIngredient.isEmpty || normalizedItem.isEmpty) {
    return 0;
  }

  var score = 0;
  if (normalizedItem == normalizedIngredient) {
    score += 100;
  }
  if (normalizedItem.contains(normalizedIngredient)) {
    score += 60;
  }
  if (normalizedIngredient.contains(normalizedItem)) {
    score += 30;
  }

  final ingredientTokens = _matchTokens(normalizedIngredient);
  final itemTokens = _matchTokens(normalizedItem);
  for (final token in ingredientTokens) {
    if (itemTokens.contains(token)) {
      score += token.length >= 5 ? 15 : 10;
      continue;
    }
    if (normalizedItem.contains(token)) {
      score += 4;
    }
  }
  return score;
}

String _normalizeMatchText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ').trim();
}

Set<String> _matchTokens(String value) {
  final stopWords = <String>{
    'frisch',
    'frische',
    'frischer',
    'frisches',
    'klein',
    'kleine',
    'kleiner',
    'gross',
    'grosse',
    'grosses',
    'groß',
    'große',
    'großes',
    'etwas',
    'zum',
    'zur',
    'und',
  };
  return value
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 3 && !stopWords.contains(token))
      .toSet();
}

String _shoppingListLabel(_IngredientRowData row) {
  if (row.amountLabel == '-') {
    return row.name;
  }
  return '${row.amountLabel} ${row.name}';
}

String _buildIngredientSubtitle({
  required _IngredientRowData row,
  required List<InventoryItem> assignedItems,
}) {
  if (row.isIgnored) {
    return 'Ignoriert • ${row.amountLabel}';
  }
  if (assignedItems.isNotEmpty) {
    final assignedLabel = assignedItems.length == 1
        ? assignedItems.first.name
        : '${assignedItems.length} Artikel belegt';
    return '$assignedLabel • ${row.amountLabel}';
  }
  return row.amountLabel;
}

String? _resolvePreviewImageUrl({
  required List<InventoryItem> assignedItems,
  required List<InventoryItem> suggestions,
}) {
  if (assignedItems.isNotEmpty) {
    return assignedItems.first.imageUrl;
  }
  if (suggestions.isNotEmpty) {
    return suggestions.first.imageUrl;
  }
  return null;
}

Future<void> _toggleIgnored({
  required BuildContext context,
  required WidgetRef ref,
  required String templateId,
  required String ingredient,
  required bool isIgnored,
}) async {
  final updated = await ref
      .read(preparedMealTemplatesControllerProvider.notifier)
      .setRecipeIngredientIgnored(
        templateId: templateId,
        ingredient: ingredient,
        isIgnored: isIgnored,
      );
  if (!context.mounted || updated) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        // TODO(l10n): Localize ignore toggle error text.
        content: Text('Zutatenstatus konnte nicht gespeichert werden.'),
      ),
    );
}

Future<void> _selectInventoryAssignments({
  required BuildContext context,
  required WidgetRef ref,
  required String templateId,
  required _IngredientRowData row,
  required List<InventoryItem> inventoryItems,
}) async {
  final sortedItems = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  sortedItems.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredientName: row.name,
      item: right,
    );
    final leftScore = _ingredientMatchScore(
      ingredientName: row.name,
      item: left,
    );
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  final selectedItemIds = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final draftSelection = row.assignedInventoryItemIds.toSet();
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // TODO(l10n): Localize assignment sheet texts.
                      'Inventarartikel wählen',
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      row.name,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: sortedItems.isEmpty
                          ? const Center(
                              child: Text('Keine Inventarartikel vorhanden.'),
                            )
                          : ListView.builder(
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                final isSelected = draftSelection.contains(
                                  item.id,
                                );
                                return CheckboxListTile(
                                  value: isSelected,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.name),
                                  subtitle: Text(_inventoryAmountLabel(item)),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked ?? false) {
                                        draftSelection.add(item.id);
                                      } else {
                                        draftSelection.remove(item.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => dialogContext.pop(),
                          child: const Text('Abbrechen'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => dialogContext.pop(
                            draftSelection.toList(growable: false),
                          ),
                          child: const Text('Übernehmen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (!context.mounted || selectedItemIds == null) {
    return;
  }

  final updated = await ref
      .read(preparedMealTemplatesControllerProvider.notifier)
      .setRecipeIngredientAssignments(
        templateId: templateId,
        ingredient: row.rawIngredient!,
        inventoryItemIds: selectedItemIds,
      );
  if (!context.mounted || updated) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        // TODO(l10n): Localize assignment save error text.
        content: Text('Inventar-Belegung konnte nicht gespeichert werden.'),
      ),
    );
}

Future<void> _addIngredientToShoppingList({
  required BuildContext context,
  required WidgetRef ref,
  required String shoppingListLabel,
}) async {
  final added = await ref
      .read(shoppingListControllerProvider.notifier)
      .addItem(name: shoppingListLabel);
  if (!context.mounted || added) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        // TODO(l10n): Localize shopping list save error text.
        content: Text(
          'Zutat konnte nicht zur Einkaufsliste hinzugefügt werden.',
        ),
      ),
    );
}
