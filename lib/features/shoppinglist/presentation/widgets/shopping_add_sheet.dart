import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_quick_entry.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_add_hit_list.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the sheet that adds entries one after another. It stays open until
/// the user is done. [suggestions] are offered as hits while typing.
Future<void> showShoppingAddSheet(
  BuildContext context, {
  required List<ShoppingSuggestion> suggestions,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _AddSheet(suggestions: suggestions),
);

/// An entry the sheet added: its id tells chips with the same label apart.
typedef _Added = ({int id, String label, ShoppingListRevert revert});

enum _Failure { add, takeBack }

class _AddSheet extends ConsumerStatefulWidget {
  const new({required this.suggestions});

  final List<ShoppingSuggestion> suggestions;

  @override
  ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  /// What this sheet added, newest first, each with the way back.
  final _added = <_Added>[];
  var _nextId = 0;
  var _saving = false;
  _Failure? _failure;

  @override
  void initState() {
    super.initState();
    _field.addListener(() => setState(() => _failure = null));
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add(
    String name,
    String? brand,
    int quantity, {
    ShoppingPlannedMeal? plannedFor,
  }) async {
    if (_saving || name.trim().isEmpty) return;
    setState(() => _saving = true);
    final label = quantity > 1
        ? AppLocalizations.of(context)!.shoppingListCartEntry(quantity, name)
        : name;
    final revert = await ref
        .read(shoppingListControllerProvider.notifier)
        .addItemWithRevert(
          name: name,
          brand: brand,
          plannedFor: plannedFor,
          quantity: quantity,
          isPrivate: ref.read(shoppingListScopeControllerProvider).addsPrivate,
        );
    if (!mounted) return;
    if (revert != null) _field.clear();
    setState(() {
      _saving = false;
      _failure = revert == null ? _Failure.add : null;
      if (revert != null) {
        _added.insert(0, (id: _nextId++, label: label, revert: revert));
      }
    });
    _focus.requestFocus();
  }

  /// Takes [added] back, and with it every newer addition to the same entry,
  /// so that no newer change is lost.
  Future<void> _takeBack(_Added added) async {
    if (_saving) return;
    setState(() => _saving = true);
    final chain = [
      for (final index in shoppingListRevertChain([
        for (final added in _added) added.revert,
      ], _added.indexOf(added)))
        _added[index],
    ];
    final reverted = await ref
        .read(shoppingListControllerProvider.notifier)
        .revertAll([for (final added in chain) added.revert]);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failure = reverted ? null : _Failure.takeBack;
      if (reverted) _added.removeWhere(chain.contains);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = parseShoppingQuickEntry(_field.text);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              AppShopping.addSheetHeightFraction,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldRow(l10n, entry),
            if (_added.isNotEmpty) _addedRow(l10n, Theme.of(context)),
            Flexible(
              child: ShoppingAddHitList(
                entry: entry,
                suggestions: widget.suggestions,
                onAdd: (name, brand, {plannedFor}) =>
                    _add(name, brand, entry.quantity, plannedFor: plannedFor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(AppLocalizations l10n, ShoppingQuickEntry entry) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: ShoppingListPageKeys.addSheetField,
            controller: _field,
            focusNode: _focus,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.shoppingAddFieldHint,
              helperText: entry.quantity > 1
                  ? l10n.shoppingAddQuantityHint(entry.quantity)
                  : null,
              errorText: switch (_failure) {
                _Failure.add => l10n.shoppingListAddFailedError,
                _Failure.takeBack => l10n.shoppingAddTakeBackFailed,
                null => null,
              },
            ),
            onSubmitted: (_) => _add(entry.text, null, entry.quantity),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        TextButton(
          key: ShoppingListPageKeys.addSheetDoneButton,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shoppingListFinishAction),
        ),
      ],
    ),
  );

  Widget _addedRow(AppLocalizations l10n, ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xxl,
      AppSpacing.md,
      AppSpacing.xxl,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shoppingAddAddedTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (index, added) in _added.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  key: ShoppingListPageKeys.addSheetAdded(added.id),
                  tooltip: l10n.shoppingAddTakeBackAction(added.label),
                  avatar: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  label: Text(added.label),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onPressed: () => _takeBack(added),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
