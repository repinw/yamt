# Meal Templates Feature

## Purpose

Meal templates owns the recipe link import and the review of an imported
recipe before it is saved as a prepared-meal template.

## Owns

- The recipe link sheet and the import flow.
- The import review page and its route arguments.

## Does Not Own

- Prepared meal persistence, template repositories, or mutation workflows.
- Inventory item storage, matching domain models, or inventory consumption.
- Recipe ingredient parsing rules.
- The Kochbuch tab (`cookbook_new`).

## Public UI

- `MealTemplateImportReviewPage`: review of an imported recipe.
- `presentation/meal_template_recipe_import_flow.dart`:
  `startRecipeTemplateImport` asks for a recipe link, imports it, and opens
  the review.
