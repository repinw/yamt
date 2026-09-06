import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_food_log_feedback/diary_food_log_feedback_card.dart';

export 'diary_food_log_feedback_card.dart';
export 'diary_food_log_feedback_macro_row.dart';

/// Keeps food feedback visible without moving the diary's scroll position.
class DiaryFoodLogFeedbackHost extends ConsumerWidget {
  /// Wraps the diary's existing content.
  const DiaryFoodLogFeedbackHost({required this.child, super.key});

  /// Existing diary scroll view and background.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref
        .watch(diaryFoodLogFeedbackControllerProvider)
        .firstOrNull;
    final inset = responsivePageHorizontalPadding(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (feedback != null)
          Positioned(
            left: inset,
            right: inset,
            bottom:
                AppSizes.homeShellBottomBarClearance +
                MediaQuery.paddingOf(context).bottom +
                AppSpacing.sm,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.narrowContentMaxWidth,
                ),
                child: DiaryFoodLogFeedbackCard(
                  key: ValueKey(feedback.startedAt),
                  feedback: feedback,
                  onDismiss: () => ref
                      .read(diaryFoodLogFeedbackControllerProvider.notifier)
                      .dismiss(feedback),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
