import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';

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
          Card(
            child: Padding(
              padding: AppInsets.card,
              child: Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: FlexColumnWidth(2.6),
                  1: FlexColumnWidth(1.2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Zutat',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Menge',
                          style: Theme.of(context).textTheme.labelLarge,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  for (final row in ingredientRows)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(row.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            row.amountLabel,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _IngredientRowData {
  const _IngredientRowData({required this.name, required this.amountLabel});

  final String name;
  final String amountLabel;
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
          selectedPortions: selectedPortions,
          basePortions: template.totalPortions,
        ),
      )
      .toList(growable: false);
}

_IngredientRowData _scaledRecipeIngredient(
  String ingredient, {
  required int selectedPortions,
  required int basePortions,
}) {
  final trimmed = ingredient.trim();
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(\S+)\s+(.+)$',
  ).firstMatch(trimmed);
  if (match == null) {
    return _IngredientRowData(name: trimmed, amountLabel: '-');
  }

  final rawQuantity = match.group(1);
  final unit = match.group(2);
  final name = match.group(3);
  if (rawQuantity == null || unit == null || name == null) {
    return _IngredientRowData(name: trimmed, amountLabel: '-');
  }

  final parsedQuantity = double.tryParse(rawQuantity.replaceAll(',', '.'));
  if (parsedQuantity == null || basePortions <= 0) {
    return _IngredientRowData(name: name, amountLabel: '$rawQuantity $unit');
  }

  final scaledQuantity = parsedQuantity * selectedPortions / basePortions;
  return _IngredientRowData(
    name: name,
    amountLabel: '${_formatAmount(scaledQuantity)} $unit',
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
