import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_candidate_picker_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Selection outcome kind from the candidate picker sheet.
enum InventoryBarcodeCandidateSelectionKind {
  /// A product candidate was selected.
  candidate,

  /// User opted to create a manual product instead.
  manual,
}

/// Selected item from the barcode candidate picker bottom sheet.
class InventoryBarcodeCandidateSelection {
  /// Selection of a concrete product candidate.
  const new candidate({required this.candidate, required this.action})
    : kind = InventoryBarcodeCandidateSelectionKind.candidate;

  /// Selection of manual product creation.
  const new manual()
    : kind = InventoryBarcodeCandidateSelectionKind.manual,
      candidate = null,
      action = null;

  /// Selection kind.
  final InventoryBarcodeCandidateSelectionKind kind;

  /// Chosen candidate if kind is
  /// [InventoryBarcodeCandidateSelectionKind.candidate].
  final InventoryBarcodeLookupCandidate? candidate;

  /// Chosen candidate action.
  final InventoryBarcodeCandidateAction? action;
}

/// Resolves learned and OpenFoodFacts candidates for [barcode].
Future<List<InventoryBarcodeLookupCandidate>>
resolveInventoryBarcodeCandidates({
  required WidgetRef ref,
  required String barcode,
}) {
  return ref
      .read(productSearchGatewayProvider)
      .resolveBarcodeCandidates(barcode: barcode);
}

/// Displays the candidate picker sheet and returns user's selection.
Future<InventoryBarcodeCandidateSelection?> pickInventoryBarcodeCandidate({
  required BuildContext context,
  required List<InventoryBarcodeLookupCandidate> candidates,
  required bool showActionButtons,
  required bool eatOnly,
  required bool canCreateManual,
}) {
  return showModalBottomSheet<InventoryBarcodeCandidateSelection>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return InventoryBarcodeCandidatePickerSheet(
        candidates: candidates,
        showActionButtons: showActionButtons,
        eatOnly: eatOnly,
        onSelect: (candidate, action) => _popRoute(
          sheetContext,
          InventoryBarcodeCandidateSelection.candidate(
            candidate: candidate,
            action: action,
          ),
        ),
        onCreateManual: canCreateManual
            ? () => _popRoute(
                sheetContext,
                const InventoryBarcodeCandidateSelection.manual(),
              )
            : null,
      );
    },
  );
}

/// Handles presenting candidates, routing selection, and fallback manual
/// creation.
///
/// Returns `true` if the scanner should be restarted.
Future<bool> handleInventoryBarcodeCandidates({
  required BuildContext context,
  required List<InventoryBarcodeLookupCandidate> candidates,
  required String scannedBarcode,
  required bool showActionButtons,
  required bool eatOnly,
  required InventoryBarcodeProductSelectionCallback? onProductSelected,
  required InventoryBarcodeNotFoundCallback? onProductNotFound,
  required InventoryBarcodeManualProductCallback? onCreateManualProduct,
  required void Function(String message) showSnackBar,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (scannedBarcode.isEmpty || !isSupportedBarcode(scannedBarcode)) {
    showSnackBar(l10n.inventoryManualAddLookupFailed);
    return true;
  }

  if (candidates.isEmpty) {
    final handled = await onProductNotFound?.call(scannedBarcode) ?? false;
    if (!context.mounted) {
      return false;
    }
    if (!handled) {
      showSnackBar(l10n.inventoryManualAddNotFound);
    }
    return !handled;
  }

  final selection = await pickInventoryBarcodeCandidate(
    context: context,
    candidates: candidates,
    showActionButtons: showActionButtons,
    eatOnly: eatOnly,
    canCreateManual: onCreateManualProduct != null,
  );
  if (!context.mounted || selection == null) {
    return true;
  }
  if (selection.kind == InventoryBarcodeCandidateSelectionKind.manual) {
    return _handleCreateManualProduct(
      context: context,
      scannedBarcode: scannedBarcode,
      onCreateManualProduct: onCreateManualProduct,
      onProductNotFound: onProductNotFound,
      showSnackBar: showSnackBar,
    );
  }

  final handled =
      await onProductSelected?.call(
        selection.candidate!,
        scannedBarcode,
        selection.action!,
      ) ??
      false;
  return !handled;
}

Future<bool> _handleCreateManualProduct({
  required BuildContext context,
  required String scannedBarcode,
  required InventoryBarcodeManualProductCallback? onCreateManualProduct,
  required InventoryBarcodeNotFoundCallback? onProductNotFound,
  required void Function(String message) showSnackBar,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final handled =
      await onCreateManualProduct?.call(scannedBarcode) ??
      await onProductNotFound?.call(scannedBarcode) ??
      false;
  if (!context.mounted) {
    return false;
  }
  if (!handled) {
    showSnackBar(l10n.inventoryManualAddNotFound);
  }
  return !handled;
}

void _popRoute<T extends Object?>(BuildContext context, [T? result]) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.pop(result);
    return;
  }
  Navigator.of(context).pop(result);
}
