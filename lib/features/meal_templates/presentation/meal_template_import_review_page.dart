import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';

class MealTemplateImportReviewPage extends ConsumerStatefulWidget {
  const MealTemplateImportReviewPage({super.key, required this.args});

  final MealTemplateImportReviewArgs args;

  @override
  ConsumerState<MealTemplateImportReviewPage> createState() =>
      _MealTemplateImportReviewPageState();
}

class _MealTemplateImportReviewPageState
    extends ConsumerState<MealTemplateImportReviewPage> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final importedRecipe = widget.args.importedRecipe;
    final title = _resolvedName();
    final portions = _resolvedPortions();

    return Scaffold(
      appBar: AppBar(
        // TODO(l10n): Localize meal template review texts.
        title: const Text('Rezept-Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (importedRecipe.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                importedRecipe.imageUrl!,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            importedRecipe.recipeUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Portionen: $portions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text('Zutaten', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...importedRecipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $ingredient'),
            ),
          ),
          if (importedRecipe.instructionsPreview.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Kurze Anleitung',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...importedRecipe.instructionsPreview.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $step'),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : context.pop,
                  child: const Text('Abbrechen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveTemplate,
                  child: Text(
                    _isSaving ? 'Speichert...' : 'Als Vorlage speichern',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolvedName() {
    final trimmedName = widget.args.preferredName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return widget.args.importedRecipe.title;
  }

  int _resolvedPortions() {
    final preferredPortions = widget.args.preferredPortions;
    if (preferredPortions != null && preferredPortions > 0) {
      return preferredPortions;
    }
    return widget.args.importedRecipe.servings;
  }

  Future<void> _saveTemplate() async {
    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveImportedRecipeTemplate(
          importedRecipe: widget.args.importedRecipe,
          name: widget.args.preferredName,
          totalPortions: widget.args.preferredPortions,
        );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (result.isSuccess) {
      // TODO(l10n): Localize success text.
      messenger.showSnackBar(
        const SnackBar(content: Text('Vorlage gespeichert')),
      );
      context.pop();
      return;
    }

    // TODO(l10n): Localize failure text.
    messenger.showSnackBar(
      const SnackBar(content: Text('Vorlage konnte nicht gespeichert werden.')),
    );
  }
}
