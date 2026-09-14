import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Modal darkened backdrop with card and circular progress indicator shown
/// while resolving scanned barcode candidates.
class InventoryBarcodeScannerResolvingIndicator extends StatelessWidget {
  /// Creates the resolving indicator.
  const InventoryBarcodeScannerResolvingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Card(
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox.square(
                  dimension: AppSizes.inlineProgressIndicator,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.inventoryManualAddResolving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
