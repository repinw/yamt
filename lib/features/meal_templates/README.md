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
  - `startRecipeTemplateImport` asks for a recipe link, imports it, and opens
    the review. It returns a `RecipeLinkImport`, or `null` when the cook
    closes the sheet or the review.
  - `importRecipeTemplate` imports a given link without asking.
  - `RecipeLinkImport`: `RecipeLinkSaved` (the template id) or
    `RecipeLinkUnreadable` (the link).
  - `recipeLinkReadingKey`: the key of the dialog that shows while the page
    is read.

## Rules

- The review page pops with the id of the saved template; it shows no
  snackbar and no undo.
