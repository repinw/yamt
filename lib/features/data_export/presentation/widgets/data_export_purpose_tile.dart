import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One choice of who the export is for, with the files it writes.
class DataExportPurposeTile extends StatelessWidget {
  /// Creates the tile of [purpose].
  const new({
    required this.purpose,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Stable key of the tile of [purpose].
  static ValueKey<String> keyOf(DataExportPurpose purpose) =>
      ValueKey<String>('data-export-purpose-${purpose.name}');

  /// The purpose of this tile.
  final DataExportPurpose purpose;

  /// Whether this purpose is picked.
  final bool selected;

  /// Called with [purpose] on a tap.
  final ValueChanged<DataExportPurpose> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (icon, title, description) = switch (purpose) {
      DataExportPurpose.ai => (
        Icons.auto_awesome_outlined,
        l10n.dataExportPurposeAi,
        l10n.dataExportPurposeAiDescription,
      ),
      DataExportPurpose.advisor => (
        Icons.person_outline_rounded,
        l10n.dataExportPurposeAdvisor,
        l10n.dataExportPurposeAdvisorDescription,
      ),
      DataExportPurpose.self => (
        Icons.bar_chart_rounded,
        l10n.dataExportPurposeSelf,
        l10n.dataExportPurposeSelfDescription,
      ),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: selected
          ? BorderSide(color: colors.onSurface, width: AppSizes.selectedBorder)
          : BorderSide.none,
    );
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLow,
        shape: shape,
        child: AppInkWell(
          key: keyOf(purpose),
          customBorder: shape,
          onTap: () => onSelected(purpose),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Icon(icon),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.onSurface : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
