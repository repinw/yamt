import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/presentation/widgets/product_candidate_thumbnail.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dialog enabling the user to search products in the catalog.
class ReceiptProductSearchDialog extends StatefulWidget {
  /// Creates a [ReceiptProductSearchDialog].
  const ReceiptProductSearchDialog({
    required this.onSearch,
    super.key,
    this.initialQuery = '',
  });

  /// The search function to execute.
  final Future<List<ProductCandidate>> Function(String query) onSearch;

  /// Optional initial search query.
  final String initialQuery;

  /// Displays the search dialog and returns the selected candidate or null.
  static Future<ProductCandidate?> show(
    BuildContext context, {
    required Future<List<ProductCandidate>> Function(String query) onSearch,
    String initialQuery = '',
  }) {
    return showDialog<ProductCandidate>(
      context: context,
      builder: (context) => ReceiptProductSearchDialog(
        onSearch: onSearch,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<ReceiptProductSearchDialog> createState() =>
      _ReceiptProductSearchDialogState();
}

class _ReceiptProductSearchDialogState
    extends State<ReceiptProductSearchDialog> {
  late final TextEditingController _controller;
  List<ProductCandidate> _results = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      unawaited(_executeSearch(widget.initialQuery));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await widget.onSearch(trimmed);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } on Object catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.receiptReviewSearchProductDialogTitle ?? 'Artikel suchen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n?.receiptReviewSearchProductHint ??
                      'Produktname eingeben...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _executeSearch(_controller.text),
                  ),
                ),
                onSubmitted: _executeSearch,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                )
              else if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n?.receiptReviewNoProductsFound ??
                        'Keine Artikel gefunden',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final candidate = _results[index];
                      final subtitleParts = <String>[];
                      if (candidate.brand != null &&
                          candidate.brand!.isNotEmpty) {
                        subtitleParts.add(candidate.brand!);
                      }
                      if (candidate.formattedMacros != null) {
                        subtitleParts.add(candidate.formattedMacros!);
                      }

                      return ListTile(
                        leading: ProductCandidateThumbnail(
                          imageUrl: candidate.imageUrl,
                        ),
                        title: Text(
                          candidate.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: subtitleParts.isNotEmpty
                            ? Text(
                                subtitleParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(candidate),
                      );
                    },
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n?.inventoryReceiptBatchCloseAction ?? 'Schließen',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
