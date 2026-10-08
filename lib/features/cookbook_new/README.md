# Cookbook (new)

## Purpose

The Kochbuch tab: meals still in the pot, Vorlagen combined from the Vorrat,
and recipes with the stock state of their ingredients. It replaces the meal
templates list and later the cooking flow.

## Owns

- The Kochbuch page, its sections, and its cook actions.
- The "Frei kochen" page: the draft rows of a meal without a recipe, how
  spoken or typed text is cut into rows, and their stock state.
- The "Gekocht" page: portions or pieces, pot, and food weight of a meal in
  the pot, and discarding a combined meal there, which gives its foods back
  to the Vorrat and deletes the ones added only for it.
- The overview that sorts saved templates into Vorlagen and recipes and marks
  which foods the Vorrat holds.

## Does Not Own

- Template, meal, and Vorrat storage and their mutations (`inventory`).
- The recipe link import and its review (`meal_templates`).
- The AI recipe idea (`ai_chef`) and the kitchen utensils (`kitchen_utensils`).

## Public UI

- `CookbookPage`: the Kochbuch tab.
- `presentation/widgets/cookbook_cook_actions.dart` (`cookbookCookActions`):
  the actions that the home shell shows in its action panel on the Kochbuch
  tab.

## Rules

- A template with recipe ingredients is a recipe; one without is a Vorlage.
- A food counts as in stock when the ingredient matcher finds a Vorrat item
  that is not used up. Ignored recipe ingredients are left out.
- "Offen" shows meals that are still in the pot or have open rows, and
  have portions left.
- The food weight is the pot on the scale minus the empty utensil. A cooked
  meal without weighing stores no weight and no empty pot weight; a combined
  meal (one without rows) stores the sum of its ingredients when all are in
  grams, unless the cook weighs it instead.
- Free cooking cuts text into rows before each amount and at commas, line
  breaks, and "und"/"and". An amount at the end of a row stays with it.
- A row counts as in stock only when it has an amount in a unit that its
  best fitting Vorrat match can supply. "Kochen" takes those rows from the
  Vorrat; all other rows stay open on the saved meal.
