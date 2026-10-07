import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Für deinen Plan": what the planned meals need and the stock cannot
/// cover, by day and meal, each with a button that puts it on the list.
/// Hidden while there is nothing to show.
class ShoppingListPlanNeeds extends ConsumerStatefulWidget {
  /// Creates the block for [groups].
  const new({required this.groups, required this.onRetry, super.key});

  /// Key of the add button of [need].
  static Key addKey(ShoppingPlanNeed need) =>
      Key('shopping_plan_need_add_${need.name}_${need.day}');

  /// Key of the retry button after a failure.
  static const retryKey = Key('shopping_plan_needs_retry');

  /// The needs by day and meal, without foods already on the list.
  final AsyncValue<List<ShoppingPlanNeedGroup>> groups;

  /// Loads the needs again after a failure.
  final VoidCallback onRetry;

  @override
  ConsumerState<ShoppingListPlanNeeds> createState() =>
      _ShoppingListPlanNeedsState();
}

class _ShoppingListPlanNeedsState extends ConsumerState<ShoppingListPlanNeeds> {
  // By food, so the same food on two days is added once.
  final _pending = <(String, String)>{};

  static (String, String) _food(ShoppingPlanNeed need) => (
    normalizeShoppingListValue(need.name),
    normalizeShoppingListValue(need.brand ?? ''),
  );

  Future<void> _add(ShoppingPlanNeed need) async {
    if (!_pending.add(_food(need))) return;
    setState(() {});
    final saved = await ref
        .read(shoppingListControllerProvider.notifier)
        .addItem(name: need.name, brand: need.brand);
    if (!mounted) return;
    setState(() => _pending.remove(_food(need)));
    if (!saved) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.shoppingListAddFailedError,
        tone: AppSnackBarTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = Text(
      l10n.shoppingListPlanNeedsTitle,
      style: theme.textTheme.titleMedium,
    );
    // A reload keeps the last needs on screen.
    final groups = widget.groups;
    if (groups.value case final value? when value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            for (final group in value) ..._group(group, l10n, theme),
          ],
        ),
      );
    }
    if (groups.hasError && !groups.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            Text(l10n.shoppingListPlanNeedsLoadFailed),
            TextButton.icon(
              key: ShoppingListPlanNeeds.retryKey,
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.shoppingListPlanNeedsRetry),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> _group(
    ShoppingPlanNeedGroup group,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return [
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.shoppingListPlanNeedGroup(
          DateFormat.MMMEd(localeName).format(group.day),
          group.mealType.localizedName(l10n),
        ),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      for (final need in group.needs)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(need.name),
          subtitle: Text(_subtitle(need, l10n, localeName)),
          trailing: IconButton.outlined(
            key: ShoppingListPlanNeeds.addKey(need),
            tooltip: l10n.shoppingListAddAction,
            onPressed: _pending.contains(_food(need)) ? null : () => _add(need),
            icon: const Icon(Icons.add),
          ),
        ),
    ];
  }

  static String _subtitle(
    ShoppingPlanNeed need,
    AppLocalizations l10n,
    String localeName,
  ) {
    final number = (NumberFormat.decimalPattern(
      localeName,
    )..maximumFractionDigits = 0).format(need.amount.ceil());
    final amount = l10n.shoppingListPlanNeedAmount(
      number,
      need.inMilliliters ? l10n.caloriesUnitMilliliter : l10n.caloriesUnitGram,
    );
    final text = need.isPartial
        ? l10n.shoppingListPlanNeedMissing(amount)
        : amount;
    final brand = need.brand?.trim() ?? '';
    return brand.isEmpty ? text : l10n.shoppingListPlanNeedBrand(brand, text);
  }
}
