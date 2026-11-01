import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_holo_preview_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Debug entry that shows the budget card's holo foil without hitting the
/// target.
class DiaryHoloPreviewTile extends ConsumerWidget {
  /// Creates the entry.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSwitchListTile(
      secondary: const Icon(Icons.auto_awesome_outlined),
      title: Text(AppLocalizations.of(context)!.diaryHoloPreviewAction),
      value: ref.watch(diaryHoloPreviewControllerProvider),
      onChanged: (_) =>
          ref.read(diaryHoloPreviewControllerProvider.notifier).toggle(),
    );
  }
}
