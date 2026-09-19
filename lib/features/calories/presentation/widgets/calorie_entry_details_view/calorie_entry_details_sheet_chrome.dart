import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_header.dart';

/// Shared visual shell for the calorie entry details sheet.
///
/// The sheet is as tall as its content, up to a share of the screen height.
/// Longer content scrolls between the header and the footer.
class CalorieEntryDetailsSheetChrome extends StatelessWidget {
  /// Creates a sheet chrome wrapper.
  const new({
    required this.isSaving,
    required this.onClose,
    required this.children,
    required this.footer,
    super.key,
  });

  /// Whether a mutation is in progress.
  final bool isSaving;

  /// Close callback.
  final VoidCallback onClose;

  /// Scrollable body contents.
  final List<Widget> children;

  /// Footer shown below the body.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxSheetHeight =
        MediaQuery.sizeOf(context).height * AppSheetTokens.maxHeightFraction;
    final sheetRadius = BorderRadius.circular(AppRadius.xl + AppSpacing.xs);

    // The page covers the whole screen above the route barrier, so taps
    // outside the sheet close it here. The sheet itself swallows its taps.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isSaving ? null : onClose,
        child: SafeArea(
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
                  maxWidth: AppSheetTokens.maxWidth,
                  maxHeight: maxSheetHeight,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: sheetRadius,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: sheetRadius,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CalorieEntryDetailsSheetHeader(
                            closeTooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            isSaving: isSaving,
                            onClose: onClose,
                          ),
                          Flexible(
                            child: FocusTraversalGroup(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl,
                                  0,
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                ),
                                children: children,
                              ),
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
        ),
      ),
    );
  }
}
