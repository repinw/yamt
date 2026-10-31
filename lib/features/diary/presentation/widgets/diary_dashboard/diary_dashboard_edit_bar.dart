import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_edit_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_add_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The bar above the dashboard in edit mode: reset, add a hidden tile, and
/// "Fertig".
class DiaryDashboardEditBar extends ConsumerWidget {
  /// Creates the bar.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasHidden = ref.watch(
      diaryDashboardLayoutControllerProvider.select((l) => l.hidden.isNotEmpty),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          TextButton(
            key: DiaryDashboardKeys.reset,
            onPressed: () => unawaited(
              ref.read(diaryDashboardLayoutControllerProvider.notifier).reset(),
            ),
            child: Text(l10n.diaryDashboardReset),
          ),
          const Spacer(),
          IconButton(
            key: DiaryDashboardKeys.add,
            tooltip: l10n.diaryDashboardAddTile,
            onPressed: hasHidden
                ? () => unawaited(showDiaryDashboardAddSheet(context))
                : null,
            icon: const Icon(Icons.add),
          ),
          FilledButton(
            key: DiaryDashboardKeys.done,
            onPressed: () => ref
                .read(diaryDashboardEditControllerProvider.notifier)
                .finish(),
            child: Text(l10n.diaryDashboardDone),
          ),
        ],
      ),
    );
  }
}
