import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
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

  /// Close callback.
  final VoidCallback onClose;

  /// Scrollable body contents.
  final Widget child;

  /// Fixed footer shown below the body.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.9;
    final sheetRadius = BorderRadius.circular(
      AppRadius.xl + AppSpacing.xs,
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
                  color: colors.surfaceContainerLow,
                  borderRadius: sheetRadius,
                  border: Border.all(
                    color: colors.outlineVariant,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: sheetRadius,
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
                      Expanded(
                        child: FocusTraversalGroup(
                          child: child,
                        ),
                      ),
                      footer,
                    ],
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
