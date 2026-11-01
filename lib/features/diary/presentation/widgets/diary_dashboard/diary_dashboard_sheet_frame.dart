import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Opens a dashboard sheet with [builder] as its content.
Future<void> showDiaryDashboardSheet(
  BuildContext context,
  WidgetBuilder builder,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: builder(context),
      ),
    ),
  );
}

/// The heading row of a dashboard sheet: an icon and a name.
class DiaryDashboardSheetHeading extends StatelessWidget {
  /// Creates the heading.
  const new({required this.icon, required this.label, super.key});

  /// Icon before the name.
  final IconData icon;

  /// The name.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Icon(icon),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
