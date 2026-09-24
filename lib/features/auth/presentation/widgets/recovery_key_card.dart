import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows a recovery key with an explanation and a copy button.
class RecoveryKeyCard extends StatelessWidget {
  /// Creates the card.
  const new({required this.formattedKey, super.key});

  /// The recovery key in groups of four characters.
  final String formattedKey;

  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: formattedKey));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(l10n.recoveryKeyCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.recoveryKeyExplanation, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    formattedKey,
                    style: textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.recoveryKeyCopyTooltip,
                  onPressed: () => _copy(context, l10n),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
