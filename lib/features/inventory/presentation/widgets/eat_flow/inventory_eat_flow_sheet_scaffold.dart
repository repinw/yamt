import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
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
    this.secondaryActionText,
    this.secondaryButtonKey,
    this.onSecondaryConfirm,
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

  /// Optional secondary action text.
  final String? secondaryActionText;

  /// Optional secondary button key.
  final Key? secondaryButtonKey;

  /// Optional secondary callback.
  final VoidCallback? onSecondaryConfirm;

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
                AppEditorial.cardRadius,
              ),
              child: DecoratedBox(
                decoration: AppEditorialSurfaces.liftedCardDecoration(
                  colors,
                  borderRadius: BorderRadius.circular(
                    AppEditorial.cardRadius,
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
                      secondaryActionText: secondaryActionText,
                      secondaryButtonKey: secondaryButtonKey,
                      onSecondaryConfirm: onSecondaryConfirm,
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
