import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_header.dart';

/// Shared visual shell for the calorie entry details sheet.
class CalorieEntryDetailsSheetChrome extends StatelessWidget {
  /// Creates a sheet chrome wrapper.
  const CalorieEntryDetailsSheetChrome({
    required this.title,
    required this.isSaving,
    required this.onClose,
    required this.child,
    required this.footer,
    super.key,
  });

  /// Sheet title.
  final String title;

  /// Whether a mutation is in progress.
  final bool isSaving;

  /// Called when closing the sheet.
  final VoidCallback onClose;

  /// Main scrollable body.
  final Widget child;

  /// Fixed footer shown below the body.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.9;
    final sheetRadius = BorderRadius.circular(
      AppEditorial.cardRadius + AppSpacing.xs,
    );
    final sheetGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(
          colors.surfaceContainerHigh.withValues(alpha: 0.9),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.surfaceContainerLow.withValues(alpha: 0.96),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.99),
          colors.surface,
        ),
      ],
      stops: const [0, 0.45, 1],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: maxSheetHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: sheetRadius,
                  boxShadow: [
                    AppEditorialSurfaces.ambientBoxShadow(
                      colors,
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: sheetRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppEditorial.glassBlur,
                      sigmaY: AppEditorial.glassBlur,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: sheetGradient,
                        borderRadius: sheetRadius,
                        border: Border.all(
                          color: AppEditorialSurfaces.ghostBorder(
                            colors,
                          ).withValues(alpha: 0.9),
                        ),
                      ),
                      child: Column(
                        children: [
                          CalorieEntryDetailsSheetHeader(
                            title: title,
                            closeTooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                            isSaving: isSaving,
                            onClose: onClose,
                          ),
                          Flexible(child: child),
                          footer,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
