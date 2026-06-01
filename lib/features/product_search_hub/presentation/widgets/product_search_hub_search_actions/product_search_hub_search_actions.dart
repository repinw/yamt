import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubSearchActionHeight = 58.0;
const _productSearchHubSearchActionIconSize = 18.0;

/// Quick actions shown below the focused product search field.
class ProductSearchHubSearchActions extends StatelessWidget {
  /// Creates focused search quick actions.
  const ProductSearchHubSearchActions({
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    super.key,
  });

  /// AI action callback.
  final VoidCallback onAiPressed;

  /// Create-own-product action callback.
  final VoidCallback onCreateOwnPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 2;
        final itemWidth =
            (constraints.maxWidth - (AppSpacing.sm * (columnCount - 1))) /
            columnCount;

        return Focus(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ProductSearchHubSearchActionButton(
                key: const Key('product_search_hub_search_ai_action'),
                icon: Icons.auto_awesome_rounded,
                label: l10n.productSearchHubAiAction,
                width: itemWidth,
                onPressed: onAiPressed,
              ),
              _ProductSearchHubSearchActionButton(
                key: const Key('product_search_hub_search_create_own_action'),
                icon: Icons.edit_note_rounded,
                label: l10n.productSearchHubCreateOwnAction,
                width: itemWidth,
                onPressed: onCreateOwnPressed,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductSearchHubSearchActionButton extends StatelessWidget {
  const _ProductSearchHubSearchActionButton({
    required this.icon,
    required this.label,
    required this.width,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _productSearchHubSearchActionHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _productSearchHubSearchActionIconSize),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
