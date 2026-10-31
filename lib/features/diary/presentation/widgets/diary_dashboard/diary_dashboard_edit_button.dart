import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_edit_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The way back into edit mode when every tile is hidden and nothing is
/// left to long press.
class DiaryDashboardEditButton extends ConsumerWidget {
  /// Creates the button.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IconButton(
        key: DiaryDashboardKeys.edit,
        tooltip: AppLocalizations.of(context)!.diaryDashboardEdit,
        onPressed: () =>
            ref.read(diaryDashboardEditControllerProvider.notifier).start(),
        icon: const Icon(Icons.dashboard_customize_outlined),
      ),
    );
  }
}
