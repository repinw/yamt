import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';

/// Route arguments for the full-screen receipt review page.
class InventoryReceiptReviewPageArgs {
  const InventoryReceiptReviewPageArgs({
    required this.items,
    required this.onSaveTap,
    this.receiptPreviewBytes,
  });

  final List<ReceiptReviewItemDraft> items;
  final Uint8List? receiptPreviewBytes;
  final Future<bool> Function(List<ReceiptReviewItemDraft> items) onSaveTap;
}

/// Full-screen page for reviewing scanned receipt items before saving them.
class InventoryReceiptReviewPage extends StatefulWidget {
  const InventoryReceiptReviewPage({super.key, required this.args});

  final InventoryReceiptReviewPageArgs args;

  @override
  State<InventoryReceiptReviewPage> createState() =>
      _InventoryReceiptReviewPageState();
}

class _InventoryReceiptReviewPageState
    extends State<InventoryReceiptReviewPage> {
  var _canPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _finishWith(false);
      },
      child: Scaffold(
        body: InventoryReceiptReviewSheet(
          items: widget.args.items,
          receiptPreviewBytes: widget.args.receiptPreviewBytes,
          onCancelTap: () => _finishWith(false),
          onSaveTap: (reviewedItems) async {
            final saved = await widget.args.onSaveTap(reviewedItems);
            if (!mounted) {
              return;
            }
            _finishWith(saved);
          },
        ),
      ),
    );
  }

  void _finishWith(bool result) {
    if (_canPop || !mounted) {
      return;
    }

    setState(() {
      _canPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.pop(result);
    });
  }
}
