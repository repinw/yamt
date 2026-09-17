import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/presentation/widgets/product_candidate_thumbnail.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// List displaying candidate products suggested for a receipt line item.
class ReceiptItemCandidatesList extends StatelessWidget {
  /// Creates a [ReceiptItemCandidatesList].
  const new({
    required this.candidates,
    required this.onSelectCandidate,
    super.key,
  });

  /// The candidate products available for selection.
  final List<ProductCandidate> candidates;

  /// Callback triggered when a candidate is chosen.
  final ValueChanged<ProductCandidate> onSelectCandidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.receiptReviewSuggestedAlternatives ??
              'Vorgeschlagene Alternativen:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        ...candidates.map((c) => _buildCandidateTile(context, c, colors)),
      ],
    );
  }

  Widget _buildCandidateTile(
    BuildContext context,
    ProductCandidate c,
    ColorScheme colors,
  ) {
    final l10n = AppLocalizations.of(context);
    final subtitleParts = <String>[];
    if (c.brand != null && c.brand!.isNotEmpty) subtitleParts.add(c.brand!);
    if (c.formattedMacros != null) subtitleParts.add(c.formattedMacros!);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: ProductCandidateThumbnail(imageUrl: c.imageUrl),
      title: Text(
        c.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitleParts.isNotEmpty
          ? Text(
              subtitleParts.join(' · '),
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: TextButton(
        onPressed: () => onSelectCandidate(c),
        child: Text(l10n?.receiptReviewSelectCandidateAction ?? 'Wählen'),
      ),
      onTap: () => onSelectCandidate(c),
    );
  }
}
