import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/features/home/widgets/inventory_expanded_fab_actions.dart';
import 'package:yamt/features/home/widgets/inventory_expanded_fab_menu.dart';
import 'package:yamt/features/home/widgets/inventory_fab_action_sheet_launcher.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_main_fab_button.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
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
    _subscribedObserver?.unsubscribe(this);
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
                actions: buildInventoryExpandedFabActions(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  isCameraEnabled: isCameraEnabled,
                  runAction: _runAction,
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
      showInventoryFabActionSheet(
        context: context,
        ref: ref,
        l10n: l10n,
        isCameraEnabled: isCameraEnabled,
      ).whenComplete(() {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
      }),
    );
  }
}
