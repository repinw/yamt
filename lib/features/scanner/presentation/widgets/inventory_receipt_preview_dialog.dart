import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Full-screen dialog that shows the scanned receipt preview image.
class InventoryReceiptPreviewDialog extends StatelessWidget {
  const InventoryReceiptPreviewDialog({
    super.key,
    required this.receiptPreviewBytes,
  });

  final Uint8List? receiptPreviewBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final hasPreview =
        receiptPreviewBytes != null && receiptPreviewBytes!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.inverseSurface.withValues(
                      alpha: 0.28,
                    ),
                    foregroundColor: colors.onInverseSurface,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AspectRatio(
                          aspectRatio: 1 / 1.9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: hasPreview
                                ? InteractiveViewer(
                                    child: Image.memory(
                                      receiptPreviewBytes!,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  )
                                : _ReceiptPreviewPlaceholder(
                                    title: l10n
                                        .inventoryReceiptReviewOriginalReceiptTitle,
                                    subtitle: l10n
                                        .inventoryReceiptReviewOriginalReceiptUnavailable,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviewPlaceholder extends StatelessWidget {
  const _ReceiptPreviewPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
