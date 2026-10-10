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
  to the Vorrat and deletes the ones added only for it, and the "Ins
  Kochbuch" switch that also saves the cooked meal as a template.
- The recipe page: a recipe sized for the chosen portions, which Vorrat food
  supplies each ingredient, and cooking it into the pot.
- The Kochhelfer of a recipe: its ingredients and steps, then one sentence
  per screen with the ingredients it names and what else the cook says or
  types for the pot, before the meal goes into the pot.
- The ingredient check of a recipe ("Zutaten prüfen"): what comes from the
  Vorrat, what goes on the shopping list, and what is ignored, changes to
  the ingredients for one cooking, and saving those choices on the recipe.
- The overview that sorts saved templates into Vorlagen and recipes and marks
  which foods the Vorrat holds.

## Does Not Own

- Template, meal, and Vorrat storage and their mutations (`inventory`).
- The recipe link import and its review (`meal_templates`).
- The shopping list (`shoppinglist`) and the food pick (`product_search_hub`,
  opened through inventory's `PreparedMealPendingFoodFlow`).
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
- On the recipe page an ingredient takes the cook's pick, else the Vorrat
  items the recipe saved for it that still fit, else the best fitting match.
  A pick counts for this cooking only.
- An ingredient counts as partly there when its Vorrat items hold less than
  it needs in grams or milliliters; pieces count as there.
- The ingredient check saves every Vorrat food it takes and every ignored
  ingredient on the recipe; its own picks count only once "Fertig" saves
  them. A food that "Hab ich" added does not move its ingredient out of the
  missing ones. Its shopping list text is written like an open row of a
  meal: the missing part of a partly stocked ingredient ("200 g Karotten"),
  else the whole ingredient. The recipe card counts an ingredient as sorted
  once that text is on the list.
- Ingredient changes are written for the recipe's own portions, like the
  saved ingredients, and the check shows them for the chosen ones. Without
  "Änderungen ins Rezept übernehmen" the recipe is saved with its own
  ingredients, the choices for a changed ingredient go to its saved text,
  and the recipe page keeps the changes until it closes, with the choices
  for added ingredients as its picks. The check and the recipe page keep
  choices and picks by the saved ingredient, so they stay when its amount
  changes.
