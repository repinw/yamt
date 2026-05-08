import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/features/inventory/presentation/inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_action_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_fab_menu_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_main_fab_button.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory action fab.
@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
class InventoryActionFab extends ConsumerStatefulWidget {
  /// The inventory action fab for the shell Scaffold slot.
  const InventoryActionFab({super.key}) : embedded = false;

  /// The inventory action fab for inline empty-state placement.
  const InventoryActionFab.embedded({super.key}) : embedded = true;

  /// Whether to render inside normal content instead of Scaffold FAB chrome.
  final bool embedded;

  @override
  ConsumerState<InventoryActionFab> createState() => _InventoryActionFabState();
}

class _InventoryActionFabState extends ConsumerState<InventoryActionFab>
    with RouteAware {
  final LayerLink _fabLayerLink = LayerLink();
  OverlayEntry? _expandedMenuEntry;
  RouteObserver<ModalRoute<void>>? _subscribedObserver;
  ModalRoute<void>? _subscribedRoute;
  bool _isSheetOpen = false;
  bool _isExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.embedded) {
      return;
    }
    final observer = ref.read(appRouteObserverProvider);
    final route = ModalRoute.of(context);
    if (observer == _subscribedObserver && route == _subscribedRoute) {
      return;
    }
    final previousObserver = _subscribedObserver;
    if (previousObserver != null) {
      previousObserver.unsubscribe(this);
    }
    if (route != null) {
      observer.subscribe(this, route);
    }
    _subscribedObserver = observer;
    _subscribedRoute = route;
  }

  @override
  void didPushNext() {
    _collapseExpandedMenu();
  }

  @override
  void didPop() {
    _collapseExpandedMenu();
  }

  @override
  void dispose() {
    _subscribedObserver?.unsubscribe(this);
    _removeExpandedMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final isCameraEnabled = ref.watch(receiptCameraSupportedProvider);
    final isBusy =
        flowState.isLoading ||
        batchState.status == ReceiptBatchFlowStatus.running;

    if (widget.embedded) {
      return InventoryMainFabButton(
        buttonKey: const Key('inventory_action_fab_button'),
        isBusy: isBusy,
        icon: Icons.add_rounded,
        tooltip: l10n.inventoryFabTooltip,
        onPressed: isBusy || _isSheetOpen
            ? null
            : () => _showActionsSheet(
                context: context,
                l10n: l10n,
                isCameraEnabled: isCameraEnabled,
              ),
      );
    }

    return PopScope(
      canPop: !_isExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _collapseExpandedMenu();
        }
      },
      child: CompositedTransformTarget(
        link: _fabLayerLink,
        child: Visibility(
          visible: !_isExpanded,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: InventoryMainFabButton(
            buttonKey: const Key('inventory_action_fab_button'),
            isBusy: isBusy,
            icon: Icons.add_rounded,
            tooltip: l10n.inventoryFabTooltip,
            onPressed: isBusy
                ? null
                : () => _showExpandedMenu(
                    context: context,
                    l10n: l10n,
                    isCameraEnabled: isCameraEnabled,
                  ),
          ),
        ),
      ),
    );
  }

  void _runAction(Future<void> Function() action) {
    _collapseExpandedMenu();
    unawaited(action());
  }

  void _showExpandedMenu({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isCameraEnabled,
  }) {
    if (_isExpanded) {
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    setState(() {
      _isExpanded = true;
    });
    _expandedMenuEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('inventory_action_fab_overlay_dismiss'),
                behavior: HitTestBehavior.opaque,
                onTap: _collapseExpandedMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _fabLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.bottomRight,
              child: InventoryExpandedFabMenu(
                actions: _buildActions(
                  context: overlayContext,
                  l10n: l10n,
                  isCameraEnabled: isCameraEnabled,
                ),
                closeButton: InventoryMainFabButton(
                  buttonKey: const Key('inventory_action_fab_close_button'),
                  isBusy: false,
                  icon: Icons.close_rounded,
                  tooltip: l10n.inventoryFabTooltip,
                  onPressed: _collapseExpandedMenu,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_expandedMenuEntry!);
  }

  void _collapseExpandedMenu() {
    if (!_isExpanded) {
      return;
    }
    _removeExpandedMenu();
    if (!mounted) {
      return;
    }
    setState(() {
      _isExpanded = false;
    });
  }

  void _removeExpandedMenu() {
    final entry = _expandedMenuEntry;
    if (entry == null) {
      return;
    }
    _expandedMenuEntry = null;
    if (entry.mounted) {
      entry.remove();
    }
    entry.dispose();
  }

  List<Widget> _buildActions({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isCameraEnabled,
  }) {
    return [
      InventoryFabMenuAction(
        key: const Key('inventory_action_manual_search_fab'),
        heroTag: 'inventory_action_manual_search_fab',
        icon: Icons.search_rounded,
        label: l10n.inventoryActionManualSearch,
        onPressed: () => _runAction(
          () => InventoryActionSheetFlow.openManualSearch(
            context: context,
            l10n: l10n,
          ),
        ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_barcode_fab'),
        heroTag: 'inventory_action_barcode_fab',
        icon: Icons.qr_code_scanner_rounded,
        label: l10n.diaryQuickEatSourceBarcode,
        onPressed: () => _runAction(
          () => InventoryActionSheetFlow.openBarcodeScanner(
            context: context,
            l10n: l10n,
          ),
        ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_ai_suggestion_fab'),
        heroTag: 'inventory_action_ai_suggestion_fab',
        icon: Icons.auto_awesome_rounded,
        label: l10n.inventoryActionAiSuggestion,
        onPressed: () => _runAction(
          () => InventoryActionSheetFlow.openAiSuggestion(
            context: context,
            l10n: l10n,
          ),
        ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_upload_image_pdf_fab'),
        heroTag: 'inventory_action_upload_image_pdf_fab',
        icon: Icons.upload_file_rounded,
        label: l10n.inventoryActionUploadImagePdf,
        onPressed: () => _runAction(
          () => InventoryActionSheetFlow.uploadFile(
            context: context,
            ref: ref,
            l10n: l10n,
          ),
        ),
      ),
      InventoryFabMenuAction(
        key: const Key('inventory_action_camera_fab'),
        heroTag: 'inventory_action_camera_fab',
        icon: Icons.photo_camera_rounded,
        label: l10n.inventoryActionCamera,
        tooltip: isCameraEnabled
            ? l10n.inventoryActionCamera
            : l10n.inventoryActionCameraUnsupported,
        onPressed: isCameraEnabled
            ? () => _runAction(
                () => InventoryActionSheetFlow.scanCamera(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                ),
              )
            : null,
      ),
    ];
  }

  void _showActionsSheet({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isCameraEnabled,
  }) {
    if (_isSheetOpen) {
      return;
    }
    setState(() {
      _isSheetOpen = true;
    });
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        sheetAnimationStyle: AnimationStyle.noAnimation,
        builder: (sheetContext) {
          return InventoryFabActionSheet(
            isCameraEnabled: isCameraEnabled,
            onManualSearch: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openManualSearch(
                context: context,
                l10n: l10n,
              ),
            ),
            onBarcodeScan: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openBarcodeScanner(
                context: context,
                l10n: l10n,
              ),
            ),
            onAiSuggestion: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.openAiSuggestion(
                context: context,
                l10n: l10n,
              ),
            ),
            onUploadFile: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.uploadFile(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            ),
            onScanCamera: () => _closeAndRun(
              sheetContext,
              () => InventoryActionSheetFlow.scanCamera(
                context: context,
                ref: ref,
                l10n: l10n,
              ),
            ),
          );
        },
      ).whenComplete(() {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
      }),
    );
  }

  void _closeAndRun(
    BuildContext sheetContext,
    Future<void> Function() action,
  ) {
    Navigator.of(sheetContext).pop();
    unawaited(action());
  }
}

/// Animated expanded inventory FAB menu.
class InventoryExpandedFabMenu extends StatelessWidget {
  /// Creates expanded inventory FAB menu.
  const InventoryExpandedFabMenu({
    required this.actions,
    required this.closeButton,
    super.key,
  });

  /// Action buttons shown above the close button.
  final List<Widget> actions;

  /// Button used to close the expanded menu.
  final Widget closeButton;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, progress, child) {
          return Opacity(
            opacity: progress,
            child: Transform.scale(
              alignment: Alignment.bottomRight,
              scale: 0.94 + (progress * 0.06),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final action in actions) ...[
              action,
              const SizedBox(height: AppSpacing.sm),
            ],
            closeButton,
          ],
        ),
      ),
    );
  }
}
