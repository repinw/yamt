part of '../meal_template_detail_page.dart';

class _MealTemplateEmptyIngredientsCard extends StatelessWidget {
  const _MealTemplateEmptyIngredientsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
