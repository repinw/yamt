import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Days in stock from which an item counts as old in the list.
const _oldAfterDays = 7;

/// Lets the user pick Vorrat items that must go into the recipe ("Unbedingt
/// rein"). Items are sorted with the longest in stock first. The sheet pops
/// with the picked item ids, or with `null` when the user closes it.
class AiChefMustUseSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({
    required this.items,
    required this.selectedIds,
    required this.today,
    super.key,
  });

  /// Key of the search field.
  static const searchKey = ValueKey<String>('ai-chef-must-use-search');

  /// Key of the apply action.
  static const applyKey = ValueKey<String>('ai-chef-must-use-apply');

  /// Key of the row for the item with [id].
  static ValueKey<String> rowKey(String id) =>
      ValueKey<String>('ai-chef-must-use-row-$id');

  /// The Vorrat, oldest first.
  final List<InventoryItem> items;

  /// The ids picked so far.
  final Set<String> selectedIds;

  /// The day the ages are counted to.
  final DateTime today;

  /// Shows the sheet and returns the picked ids.
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<InventoryItem> items,
    required Set<String> selectedIds,
    required DateTime today,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      // Above the recipe idea sheet, which opens on the root navigator.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AiChefMustUseSheet(
        items: items,
        selectedIds: selectedIds,
        today: today,
      ),
    );
  }

  @override
  State<AiChefMustUseSheet> createState() => _AiChefMustUseSheetState();
}

class _AiChefMustUseSheetState extends State<AiChefMustUseSheet> {
  static const _builder = AiChefInventoryInputBuilder();

  late final Set<String> _selected = {...widget.selectedIds};
  late List<InventoryItem> _visible = widget.items;

  void _filter(String query) {
    final needle = query.trim().toLowerCase();
    setState(() {
      _visible = [
        for (final item in widget.items)
          if (item.name.toLowerCase().contains(needle)) item,
      ];
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      height:
          MediaQuery.sizeOf(context).height *
          AppSheetTokens.pickListSheetHeightFactor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: AiChefMustUseSheet.searchKey,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.aiChefMustUseSearchHint,
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.aiChefMustUseOldestFirst.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Expanded(
              child: widget.items.isEmpty
                  ? Center(child: Text(l10n.aiChefMustUseEmpty))
                  : ListView.separated(
                      itemCount: _visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _visible[index];
                        final days = _builder.daysInStock(item, widget.today);
                        return AppCheckboxListTile(
                          key: AiChefMustUseSheet.rowKey(item.id),
                          value: _selected.contains(item.id),
                          onChanged: (_) => _toggle(item.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          secondary: Text(
                            l10n.aiChefMustUseDays(days),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: days >= _oldAfterDays
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: AiChefMustUseSheet.applyKey,
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text(l10n.aiChefMustUseApply(_selected.length)),
            ),
          ],
        ),
      ),
    );
  }
}
