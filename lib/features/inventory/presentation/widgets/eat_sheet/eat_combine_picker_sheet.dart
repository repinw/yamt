import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the user pick a stock item to log together with the hub's item.
Future<InventoryItem?> showEatCombinePickerSheet(
  BuildContext context, {
  required List<InventoryItem> candidates,
}) {
  return showModalBottomSheet<InventoryItem>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: FoodLabelColors.of(context).paper,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _EatCombinePicker(candidates: candidates),
  );
}

class _EatCombinePicker extends StatelessWidget {
  const new({required this.candidates});

  final List<InventoryItem> candidates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * AppSizes.sheetMaxHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eatPageCombinePickerTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.ink),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  l10n.eatPageCombinePickerEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: colors.muted,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) =>
                      _CandidateLine(item: candidates[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidateLine extends StatelessWidget {
  const new({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brand = item.brand?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: AppInkWell(
        key: ValueKey<String>('eat_combine_candidate_${item.id}'),
        onTap: () => Navigator.of(context).pop(item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (brand != null && brand.isNotEmpty)
                  Text(
                    brand.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontFamily: AppFonts.mono,
                      color: colors.muted,
                    ),
                  ),
                Text(
                  item.name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: AppFonts.mono,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
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
