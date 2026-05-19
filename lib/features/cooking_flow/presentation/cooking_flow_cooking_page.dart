import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_builder.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_on_the_fly_adjustment_card.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'cooking_flow_cooking_page.g.dart';

const int _maxMainThreadInstructionChars = 1000;
const int _maxMainThreadIngredientCount = 20;
const int _maxMainThreadInventoryItemCount = 60;
const int _maxMainThreadInstructionMatchWork = 80;

/// Builds cooking instruction steps for the current recipe and inventory.
@Riverpod(dependencies: [InventoryItemsController])
Future<List<CookingFlowInstructionStep>> cookingInstructionSteps(
  Ref ref,
  CookingInstructionStepsRequest request,
) {
  final inventoryItems =
      ref.watch(inventoryItemsControllerProvider).asData?.value ??
      const <InventoryItem>[];
  if (!shouldBuildCookingInstructionStepsOffMain(
    template: request.template,
    inventoryItems: inventoryItems,
  )) {
    return Future<List<CookingFlowInstructionStep>>.value(
      buildCookingFlowInstructionSteps(
        template: request.template,
        introDraft: request.introDraft,
        inventoryItems: inventoryItems,
        text: request.text,
        localeCode: request.localeCode,
      ),
    );
  }
  return buildCookingFlowInstructionStepsOffMain(
    template: request.template,
    introDraft: request.introDraft,
    inventoryItems: inventoryItems,
    text: request.text,
    localeCode: request.localeCode,
  );
}

/// Whether instruction matching should run on a worker isolate.
bool shouldBuildCookingInstructionStepsOffMain({
  required PreparedMeal template,
  required List<InventoryItem> inventoryItems,
}) {
  final instructionCount = template.recipeInstructions
      .where((line) => line.trim().isNotEmpty)
      .length;
  final instructionChars = template.recipeInstructions.fold<int>(
    0,
    (total, line) => total + line.length,
  );
  final ingredientCount = template.components.isNotEmpty
      ? template.components.length
      : template.recipeIngredients.length;
  final matchWork =
      (instructionCount < 1 ? 1 : instructionCount) * ingredientCount;
  return instructionChars > _maxMainThreadInstructionChars ||
      ingredientCount > _maxMainThreadIngredientCount ||
      inventoryItems.length > _maxMainThreadInventoryItemCount ||
      matchWork > _maxMainThreadInstructionMatchWork;
}

/// Cooking step for cookflow.
class CookingFlowCookingPage extends ConsumerWidget {
  /// Creates cooking step.
  const CookingFlowCookingPage({
    required this.template,
    required this.introDraft,
    required this.adjustmentController,
    required this.adjustments,
    required this.onAddPressed,
    required this.onRemovePressed,
    super.key,
  });

  /// Current template.
  final PreparedMeal template;

  /// Intro draft with assignment and adjustment choices.
  final CookingFlowIntroDraft? introDraft;

  /// Controller for on-the-fly input.
  final TextEditingController adjustmentController;

  /// Current note list.
  final List<String> adjustments;

  /// Adds on-the-fly item.
  final VoidCallback onAddPressed;

  /// Removes on-the-fly item.
  final void Function(int index) onRemovePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final instructionSteps = ref
        .watch(
          cookingInstructionStepsProvider(
            CookingInstructionStepsRequest(
              template: template,
              introDraft: introDraft,
              text: CookingFlowInstructionText(
                unknownAmount: l10n.cookflowUnknownAmount,
                fallbackNoIngredients:
                    l10n.cookflowCookingFallbackNoIngredients,
                fallbackPrepPrefix: l10n.cookflowCookingFallbackPrepPrefix,
                fallbackCookText: l10n.cookflowCookingFallbackCookText,
              ),
              localeCode: localeCode,
            ),
          ),
        )
        .asData
        ?.value;

    return CookingFlowStepLayout(
      title: l10n.cookflowCookingTitle,
      subtitle: l10n.cookflowCookingBody,
      bottomPinnedChildHeight: _onTheFlyPinnedCardHeight,
      bottomPinnedChild: CookingFlowOnTheFlyAdjustmentCard(
        adjustmentController: adjustmentController,
        adjustments: adjustments,
        onAddPressed: onAddPressed,
        onRemovePressed: onRemovePressed,
      ),
      children: <Widget>[
        if (instructionSteps == null)
          const Center(
            child: Padding(
              padding: AppInsets.card,
              child: CircularProgressIndicator(),
            ),
          )
        else
          for (var index = 0; index < instructionSteps.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == instructionSteps.length - 1
                    ? AppSpacing.xxxxl
                    : AppSpacing.xxxl,
              ),
              child: _CookingInstructionCard(
                stepNumber: index + 1,
                instruction: instructionSteps[index],
              ),
            ),
      ],
    );
  }
}

/// Request data for cooking instruction generation.
@immutable
class CookingInstructionStepsRequest {
  /// Creates instruction generation request data.
  const CookingInstructionStepsRequest({
    required this.template,
    required this.introDraft,
    required this.text,
    required this.localeCode,
  });

  /// Recipe template.
  final PreparedMeal template;

  /// Current intro inventory draft.
  final CookingFlowIntroDraft? introDraft;

  /// Localized instruction labels.
  final CookingFlowInstructionText text;

  /// Active language code.
  final String localeCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingInstructionStepsRequest &&
            other.template == template &&
            other.introDraft == introDraft &&
            other.text == text &&
            other.localeCode == localeCode;
  }

  @override
  int get hashCode => Object.hash(template, introDraft, text, localeCode);
}

class _CookingInstructionCard extends StatelessWidget {
  const _CookingInstructionCard({
    required this.stepNumber,
    required this.instruction,
  });

  final int stepNumber;
  final CookingFlowInstructionStep instruction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppEditorial.cardRadius),
        blurRadius: 22,
        shadowOffset: const Offset(0, 10),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    for (final segment in instruction.segments)
                      TextSpan(
                        text: segment.text,
                        style: segment.isHighlight
                            ? const TextStyle(
                                color: AppSeedColors.orange,
                                fontWeight: FontWeight.w800,
                                backgroundColor: Color(0xFFFFE7D6),
                              )
                            : null,
                      ),
                  ],
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const double _onTheFlyPinnedCardHeight = 128;
