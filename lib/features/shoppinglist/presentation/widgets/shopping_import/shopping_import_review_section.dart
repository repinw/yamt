import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_review.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_import_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_rename_dialog.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_row_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The products we read, each to keep or leave out, and the button that
/// puts the kept ones on the list.
class ShoppingImportReviewSection extends ConsumerStatefulWidget {
  /// Creates the review of [review].
  const new({required this.review, super.key});

  /// What was read, with the user's changes.
  final ShoppingImportReview review;

  @override
  ConsumerState<ShoppingImportReviewSection> createState() =>
      _ShoppingImportReviewSectionState();
}

class _ShoppingImportReviewSectionState
    extends ConsumerState<ShoppingImportReviewSection> {
  var _saving = false;

  ShoppingImportController get _controller =>
      ref.read(shoppingImportControllerProvider.notifier);

  Future<void> _rename(int index) async {
    final name = await showShoppingImportRenameDialog(
      context,
      widget.review.rows[index].line.name,
    );
    if (name == null || !mounted) return;
    _controller.rename(index, name);
  }

  Future<void> _add() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.shoppingListSaveFailed;
    setState(() => _saving = true);
    final added = await _controller.addSelected();
    if (!mounted) return;
    setState(() => _saving = false);
    if (!added) {
      messenger.showAppSnackBar(failed, tone: AppSnackBarTone.error);
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = widget.review.rows;
    final selected = widget.review.selectedLines.length;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: AppInsets.page,
            itemCount: rows.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _Header(found: rows.length);
              if (index > rows.length) {
                return _Skipped(lines: widget.review.skipped);
              }
              final rowIndex = index - 1;
              return ShoppingImportRowTile(
                key: ShoppingImportKeys.row(rowIndex),
                index: rowIndex,
                row: rows[rowIndex],
                onToggle: () => _controller.toggle(rowIndex),
                onRename: () => _rename(rowIndex),
              );
            },
          ),
        ),
        Padding(
          padding: AppInsets.page,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ShoppingImportKeys.addButton,
              onPressed: _saving || selected == 0 ? null : _add,
              child: Text(l10n.shoppingImportAddAction(selected)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.found});

  final int found;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shoppingImportFoundCount(found),
            key: ShoppingImportKeys.foundCount,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.shoppingImportReviewHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Skipped extends StatelessWidget {
  const new({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      key: ShoppingImportKeys.skipped,
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.shoppingImportSkipped(lines.length),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in lines) Text(line, style: muted),
        ],
      ),
    );
  }
}
