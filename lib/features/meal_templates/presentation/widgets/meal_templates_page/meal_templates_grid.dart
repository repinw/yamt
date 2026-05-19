import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'prepared_meal_template_card/prepared_meal_template_card.dart';

/// Editorial responsive grid layout for prepared meal template cards.
class MealTemplatesGrid extends StatelessWidget {
  /// Creates the template grid widget.
  const MealTemplatesGrid({
    required this.templates,
    required this.includeAppBar,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// The list of templates.
  final List<PreparedMeal> templates;

  /// Whether the page includes an app bar.
  final bool includeAppBar;

  /// Open callback.
  final void Function(PreparedMeal template) onOpen;

  /// Edit callback.
  final Future<bool> Function(PreparedMeal template) onEdit;

  /// Delete callback.
  final Future<bool> Function(String templateId) onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Premium responsive design: 3 columns on tablets (>720px),
    // 2 columns on mobile.
    final crossAxisCount = width > 720 ? 3 : 2;
    // Calculate aspect ratio dynamically for optimal height budgets.
    final childAspectRatio = width > 480 ? 0.76 : 0.68;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        includeAppBar ? AppSpacing.xxl : AppSizes.homeShellBottomBarClearance,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final template = templates[index];
            return PreparedMealTemplateCard(
              template: template,
              onOpenPressed: () => onOpen(template),
              onEditPressed: onEdit,
              onDeletePressed: onDelete,
            );
          },
          childCount: templates.length,
        ),
      ),
    );
  }
}
