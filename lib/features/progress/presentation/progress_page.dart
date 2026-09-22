import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_progress_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Home tab that shows how the current week and the longer trend are going.
class ProgressPage extends ConsumerWidget {
  /// Creates the progress page.
  const new({super.key});

  /// Stable key of the TDEE trend entry.
  static const tdeeTrendTileKey = ValueKey<String>('progress-tdee-trend-tile');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final today = normalizeLocalDay(ref.watch(clockProvider)());

    return CustomScrollView(
      slivers: [
        HomeShellTabTopChrome(title: l10n.homeProgress),
        SliverPadding(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.md,
            bottom: homeShellPageBottomPadding(context),
          ),
          sliver: SliverList.list(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.narrowContentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DiaryWeeklyProgressSection(selectedDay: today),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        key: tdeeTrendTileKey,
                        leading: const Icon(Icons.insights_rounded),
                        title: Text(l10n.progressTdeeTrendTitle),
                        subtitle: Text(l10n.progressTdeeTrendSubtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => unawaited(
                          context.push(AppRoutes.homeCaloriesAnalytics),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
