import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_overlay.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_stage.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_trigger.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_page_header.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_dock.dart';

/// Scrollable content of one diary day: daily card, header, and meals.
///
/// Each day owns its macro strip, so neighbouring days can be shown side by
/// side while the user swipes between them.
class DiaryDayView extends ConsumerStatefulWidget {
  /// Creates the view of [day].
  const new({
    required this.day,
    required this.showMacroStrip,
    required this.weeklyCheckInKey,
    super.key,
  });

  /// Normalized diary day.
  final DateTime day;

  /// Whether the compact macro strip appears once the daily card scrolls
  /// away.
  final bool showMacroStrip;

  /// Key of the weekly check-in section, shared by all days.
  final GlobalKey weeklyCheckInKey;

  @override
  ConsumerState<DiaryDayView> createState() => _DiaryDayViewState();
}

class _DiaryDayViewState extends ConsumerState<DiaryDayView> {
  final _macroStripAnchors = DiaryMacroStripAnchors();
  final ValueNotifier<DiaryMacroStripStage> _macroStripStage = ValueNotifier(
    DiaryMacroStripStage.hidden,
  );

  @override
  void dispose() {
    _macroStripStage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPagePadding = responsivePageHorizontalPadding(context);
    // The quick-eat dock covers the bottom of the page.
    final bottomPagePadding =
        homeShellPageBottomPadding(context) + diaryQuickEatDockHeight;
    final dashboardData = ref
        .watch(diaryDayDashboardControllerProvider(widget.day))
        .data;

    return Stack(
      children: [
        CustomScrollView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            if (widget.showMacroStrip)
              DiaryMacroStripTrigger(
                anchors: _macroStripAnchors,
                stage: _macroStripStage,
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPagePadding,
                0,
                horizontalPagePadding,
                AppSpacing.xs,
              ),
              sliver: SliverToBoxAdapter(
                child: _NarrowContent(
                  child: DiaryBalanceCard(
                    key: _macroStripAnchors.card,
                    kcalBarKey: _macroStripAnchors.kcalBar,
                    macroBarsKey: _macroStripAnchors.macroBars,
                    selectedDay: widget.day,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPagePadding,
                0,
                horizontalPagePadding,
                bottomPagePadding,
              ),
              sliver: SliverList.list(
                children: [
                  DiaryPageHeader(
                    selectedDay: widget.day,
                    dashboardData: dashboardData,
                    weeklyCheckInKey: widget.weeklyCheckInKey,
                  ),
                  _NarrowContent(
                    child: DiaryMealsSection(selectedDay: widget.day),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.showMacroStrip)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DiaryMacroStripOverlay(
              selectedDay: widget.day,
              stage: _macroStripStage,
              kcalRowKey: _macroStripAnchors.stripKcalRow,
            ),
          ),
      ],
    );
  }
}

/// Centers page content at the narrow content width.
class _NarrowContent extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.narrowContentMaxWidth,
        ),
        // Fills the width up to the maximum instead of shrinking to fit.
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
