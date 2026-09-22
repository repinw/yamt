import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_intro_inventory_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_inventory_coordinator.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_inventory_header.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card containing inventory checks and conflict resolution during cook flow
/// intro.
class CookingFlowInventoryCheckCard extends ConsumerStatefulWidget {
  /// Creates an inventory check card.
  const new({
    required this.template,
    required this.targetPortions,
    required this.inventoryItems,
    required this.localeCode,
    required this.initialDraft,
    required this.shoppingBaselineInventoryItemIds,
    required this.resetSignal,
    required this.onRestartPressed,
    required this.onShoppingLabelsResolved,
    required this.onSelectionStateChanged,
    super.key,
  });

  /// Prepared meal template being prepared.
  final PreparedMeal template;

  /// Target portions configured by user.
  final int targetPortions;

  /// Available inventory items to match against ingredients.
  final List<InventoryItem> inventoryItems;

  /// Active locale code for number/unit formatting.
  final String localeCode;

  /// Restored or initial selection draft.
  final CookingFlowIntroDraft? initialDraft;

  /// Baseline inventory IDs before shopping list generation.
  final List<String> shoppingBaselineInventoryItemIds;

  /// Signal indicating the parent requested a reset.
  final int resetSignal;

  /// Callback when user confirms resetting the intro selection.
  final Future<void> Function() onRestartPressed;

  /// Callback when ingredient assignments resolve shopping items.
  final Future<void> Function(List<String> labels) onShoppingLabelsResolved;

  /// Callback when selection state or draft is updated.
  final ValueChanged<CookingFlowIntroSelectionState> onSelectionStateChanged;

  @override
  ConsumerState<CookingFlowInventoryCheckCard> createState() =>
      _CookingFlowInventoryCheckCardState();
}

class _CookingFlowInventoryCheckCardState
    extends ConsumerState<CookingFlowInventoryCheckCard> {
  late List<GlobalKey> _rowKeys;
  bool _syncScheduled = false;
  bool _hasScheduledDraftOverride = false;
  CookingFlowIntroDraft? _scheduledDraftOverride;

  @override
  void initState() {
    super.initState();
    _rowKeys = <GlobalKey>[];
    _scheduleControllerSync();
  }

  @override
  void didUpdateWidget(covariant CookingFlowInventoryCheckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template != widget.template ||
        oldWidget.localeCode != widget.localeCode ||
        oldWidget.resetSignal != widget.resetSignal) {
      _scheduleControllerSync();
      return;
    }
    if (oldWidget.targetPortions != widget.targetPortions) {
      final draft = ref
          .read(cookingFlowIntroInventoryControllerProvider.notifier)
          .currentDraft();
      _scheduleControllerSync(initialDraft: draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(
      cookingFlowIntroInventoryControllerProvider,
    );
    _syncRowKeys(inventoryState.rows.length);

    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final coordinator = CookingFlowInventoryCheckCoordinator(
      context: context,
      ref: ref,
      inventoryItems: widget.inventoryItems,
      localeCode: widget.localeCode,
      shoppingBaselineInventoryItemIds: widget.shoppingBaselineInventoryItemIds,
      rowKeys: _rowKeys,
      onShoppingLabelsResolved: widget.onShoppingLabelsResolved,
      onSelectionStateChanged: widget.onSelectionStateChanged,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CookingFlowInventoryCheckHeader(
          hasSelections: inventoryState.hasAnySelections,
          onRestartPressed: widget.onRestartPressed,
        ),
        const SizedBox(height: AppSpacing.md),
        if (inventoryState.rows.isEmpty)
          Text(
            l10n.cookflowEmptyIngredients,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        for (
          var index = 0;
          index < inventoryState.rows.length;
          index++
        ) ...<Widget>[
          coordinator.buildRow(
            index: index,
            key: _rowKeys[index],
            inventoryState: inventoryState,
          ),
          if (index != inventoryState.rows.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  void _scheduleControllerSync({CookingFlowIntroDraft? initialDraft}) {
    _hasScheduledDraftOverride = initialDraft != null;
    _scheduledDraftOverride = initialDraft;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      final draft = _hasScheduledDraftOverride ? _scheduledDraftOverride : null;
      _hasScheduledDraftOverride = false;
      _scheduledDraftOverride = null;
      _syncController(draft: draft);
    });
  }

  void _syncController({CookingFlowIntroDraft? draft}) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .sync(
          CookingFlowIntroInventoryInput(
            template: widget.template,
            targetPortions: widget.targetPortions,
            localeCode: widget.localeCode,
            initialDraft: widget.initialDraft,
          ),
          draft: draft,
        );
    _syncRowKeys(
      ref.read(cookingFlowIntroInventoryControllerProvider).rows.length,
    );
    CookingFlowInventoryCheckCoordinator.notifySelectionStateWith(
      ref: ref,
      inventoryItems: widget.inventoryItems,
      onSelectionStateChanged: widget.onSelectionStateChanged,
    );
  }

  void _syncRowKeys(int rowCount) {
    if (_rowKeys.length == rowCount) {
      return;
    }
    if (_rowKeys.length > rowCount) {
      _rowKeys = _rowKeys.take(rowCount).toList(growable: false);
      return;
    }
    _rowKeys = <GlobalKey>[
      ..._rowKeys,
      for (var index = _rowKeys.length; index < rowCount; index++) GlobalKey(),
    ];
  }
}
