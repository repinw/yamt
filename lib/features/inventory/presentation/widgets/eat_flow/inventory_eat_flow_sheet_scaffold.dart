import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_footer.dart';

/// Shared bottom sheet chrome for inventory eat flows.
class InventoryEatFlowSheetScaffold extends StatelessWidget {
  /// Creates shared eat flow sheet scaffold.
  const InventoryEatFlowSheetScaffold({
    required this.viewInsetsBottom,
    required this.hero,
    required this.children,
    required this.confirmActionText,
    required this.confirmButtonKey,
    required this.onConfirm,
    super.key,
  });

  /// Bottom inset from keyboard.
  final double viewInsetsBottom;

  /// Header widget.
  final Widget hero;

  /// Body children.
  final List<Widget> children;

  /// Confirm action text.
  final String confirmActionText;

  /// Confirm button key.
  final Key confirmButtonKey;

  /// Confirm callback.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: viewInsetsBottom + AppSpacing.xxxl,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppInventoryEditorial.cardRadius,
              ),
              child: DecoratedBox(
                decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
                  colors,
                  borderRadius: BorderRadius.circular(
                    AppInventoryEditorial.cardRadius,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            hero,
                            Padding(
                              padding: AppInsets.card,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: children,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InventoryEatFlowFooter(
                      confirmActionText: confirmActionText,
                      confirmButtonKey: confirmButtonKey,
                      onConfirm: onConfirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
