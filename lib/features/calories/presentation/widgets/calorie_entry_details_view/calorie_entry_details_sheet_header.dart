import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';

/// Drag handle and close button at the top of the details sheet.
class CalorieEntryDetailsSheetHeader extends StatelessWidget {
  /// Creates a details sheet header.
  const new({
    required this.closeTooltip,
    required this.isSaving,
    required this.onClose,
    super.key,
  });

  /// Tooltip shown on the close button.
  final String closeTooltip;

  /// Whether closing is currently disabled.
  final bool isSaving;

  /// Called when closing the sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.xxs,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppSheetTokens.dragHandleWidth,
            height: AppSheetTokens.dragHandleHeight,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: isSaving ? null : onClose,
              tooltip: closeTooltip,
              color: colors.onSurfaceVariant,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
