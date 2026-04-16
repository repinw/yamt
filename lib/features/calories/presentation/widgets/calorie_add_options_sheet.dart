import 'package:flutter/material.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie add options sheet.
class CalorieAddOptionsSheet extends StatelessWidget {
  /// The calorie add options sheet.
  const CalorieAddOptionsSheet({
    required this.onManualTap, required this.onBarcodeTap, super.key,
  });

  /// The on manual tap.
  final VoidCallback onManualTap;

  /// The on barcode tap.
  final VoidCallback onBarcodeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            key: CaloriesPageKeys.addOptionsManualButton,
            leading: const Icon(Icons.edit_note_outlined),
            title: Text(l10n.caloriesAddOptionManual),
            onTap: onManualTap,
          ),
          ListTile(
            key: CaloriesPageKeys.addOptionsBarcodeButton,
            leading: const Icon(Icons.qr_code_scanner_outlined),
            title: Text(l10n.caloriesAddOptionBarcode),
            onTap: onBarcodeTap,
          ),
        ],
      ),
    );
  }
}
