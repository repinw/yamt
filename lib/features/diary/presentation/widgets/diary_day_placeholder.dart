import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';

/// Cheap stand-in for a diary day that the day pages keep ready off screen.
///
/// It has the daily card's loading shape, so a fast swipe onto the day shows
/// a loading card until the full day is built.
class DiaryDayPlaceholder extends StatelessWidget {
  /// Creates the placeholder.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPagePadding = responsivePageHorizontalPadding(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPagePadding,
        AppSpacing.md,
        horizontalPagePadding,
        0,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.narrowContentMaxWidth,
          ),
          child: const DiaryBalanceLoading(),
        ),
      ),
    );
  }
}
