import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_shelf_choices_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks where the product called [name] stands and remembers the answer for
/// the household. [current] is preselected.
Future<void> showShoppingShelfPicker(
  BuildContext context, {
  required String name,
  required ShoppingShelf current,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _ShelfPicker(name: name, current: current),
);

class _ShelfPicker extends ConsumerStatefulWidget {
  const new({required this.name, required this.current});

  final String name;
  final ShoppingShelf current;

  @override
  ConsumerState<_ShelfPicker> createState() => _ShelfPickerState();
}

class _ShelfPickerState extends ConsumerState<_ShelfPicker> {
  late ShoppingShelf _shelf = widget.current;
  var _saving = false;
  var _failed = false;

  Future<void> _remember() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await ref
        .read(shoppingShelfChoicesControllerProvider.notifier)
        .choose(widget.name, _shelf);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final columns = scale > AppShopping.shelfPickerLargeTextScale ? 1 : 2;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shoppingShelfPickerTitle(widget.name),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.shoppingShelfPickerHint(widget.name),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ShelfChoices(
            columns: columns,
            selected: _shelf,
            onSelect: (shelf) => setState(() => _shelf = shelf),
          ),
          if (_failed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.shoppingShelfSaveFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: ShoppingListPageKeys.shelfRemember,
            onPressed: _saving ? null : _remember,
            child: Text(l10n.shoppingShelfRemember(widget.name)),
          ),
        ],
      ),
    );
  }
}

class _ShelfChoices extends StatelessWidget {
  const new({
    required this.columns,
    required this.selected,
    required this.onSelect,
  });

  final int columns;
  final ShoppingShelf selected;
  final ValueChanged<ShoppingShelf> onSelect;

  @override
  Widget build(BuildContext context) {
    const shelves = ShoppingShelf.values;
    return Column(
      children: [
        for (var start = 0; start < shelves.length; start += columns)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: start + column < shelves.length
                          ? _choice(context, shelves[start + column])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _choice(BuildContext context, ShoppingShelf shelf) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = shelf == selected;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        key: ShoppingListPageKeys.shelfChoice(shelf.name),
        color: isSelected ? colors.primaryContainer : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: isSelected
              ? BorderSide(color: colors.onPrimaryContainer, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: AppInkWell(
          onTap: () => onSelect(shelf),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppShopping.shelfChoiceMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    shoppingItemIconData(shoppingShelfIcon(shelf)),
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      shoppingShelfLabel(AppLocalizations.of(context)!, shelf),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
