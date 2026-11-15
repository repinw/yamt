# Cookbook (new)

## Purpose

The Kochbuch tab: cooking runs and meals still in the pot, Vorlagen combined
from the Vorrat, and recipes with their estimate and the state of their cook
run. It replaces the meal templates list.

## Owns

- The Kochbuch page, its sections, and its cook actions. A Kochbuch without a
  recipe shows "Rezept hinzufügen", which opens the "Neu" menu.
- The "Läuft" section: the household's cook runs, each with "Weiter", and
  below them the old open meals under "Aus der alten Version".
- The entries into the cooking (`kochmodus`): the recipe page's "Vorbereiten",
  "Weiter", or "Kochen", "Weiter" in "Läuft", and "Frei kochen".
- The "Gekocht" page: portions or pieces, pot, and food weight of a meal in
  the pot, and discarding any meal in the pot there, which gives its foods back
  to the Vorrat and deletes the ones added only for it, and the "Ins
  Kochbuch" switch that also saves the cooked meal as a template.
- The "Neu" menu (`NewRecipeSheet`): Scannen, Liste einfügen, Selbst tippen,
  Aus Link, and the recipe idea ("Rezeptidee").
- The recipe editor (`RecipeEditorPage`) for a new and a saved recipe: name,
  portions, ingredient lines, steps, how a scanned or pasted ingredient list
  fills it, and saving. While the name or an ingredient is missing, a hint
  above the buttons says what is still needed ("Noch nötig: …"). "Bearbeiten"
  of a list shows once the list has a line. Pasted and shared text goes to the AI template
  `recipe-text-template`; without an answer `readPastedRecipe` reads it by
  rules. Each editor keeps its own draft, and closing it with changes asks
  first. A long recipe name wraps over up to three lines, and the portions row
  sits under the photo and name block. The lines stay free text without checks; the recipe key moves with
  `withIngredientLines`; an edit saves onto the latest document of the recipe.
- The lines of the editor are edited where they stand (`RecipeEditorLineRow`):
  a tap turns a line into a field in the same place, with a button that
  removes it. A removed line comes back from the snack bar's undo
  (`restoreLine`). A line whose text changed drops its saved weight; the next
  estimate fills it (`RecipeEditorLine.keptWeight`).
- The recipe page (`RecipePage`): a recipe sized for the chosen portions, the
  state of each ingredient line, a status card, the estimate line, and the
  entry into its cooking. The macros of the estimate show as coloured columns,
  and "Zubereitung" shows only when the recipe has steps. While the estimate is
  being made, the line says "Wir schätzen die Nährwerte …" in the place of the
  values and keeps their height (`RecipeEstimateLine.waiting`). Line states and the
  card come from the recipe's cook run; "Bearbeiten" in the hero is hidden while one exists, and "Planen" there
  is shown but does nothing yet. A Vorlage is cooked into the pot from here. The
  page estimates a recipe when its estimate does not fit the lines or
  portions, once for each version of the lines and portions while it is open;
  it waits for that estimate from the first frame (`RecipeDraft.waitsForEstimate`).
  An estimate that ends without a fitting one goes into
  `RecipeDraft.failedEstimates`, so the page stops waiting
  (`RecipeEstimateService.estimate` returns whether the saved recipe holds a
  fitting estimate). The recipe page passes only the cook run's state to a line
  (`RecipeIngredientTile.state`): without a run a line shows no check. A scaled
  amount reads as exactly as in Kochmodus ("2,5 TL", `ingredientQuantityText`
  in `recipes`). The page keeps the top safe area: nothing scrolls under the
  status bar, and the hero photo starts below it.
- The recipe link flow (`RecipeLinkFlow`): a read link opens the saved recipe
  page; an unreadable page opens the editor with the link as its source and
  the name and portions the cook typed.
- The share intake (`SharedRecipeListener`): text that another app shares
  becomes a recipe. It waits with the text until the router is under `/home`.
  A link is read like "Aus Link"; other text opens the editor with the text
  pasted. A share we could not read gets a message. Android shares
  `text/plain`; iOS does not yet.
- The recipe idea window (`RecipeIdeaFlow`, `RecipeIdeaSheet`,
  `RecipeIdeaController`, `recipeIdeaViewProvider`): `ai_chef` makes the idea,
  and the window shows it as a normal recipe in a tall sheet with "Im
  Kochbuch speichern" and, after saving, a snack bar with undo. The picture
  is generated in the background and fades in. It is uploaded only after
  saving and set on the saved recipe; closing the window without saving
  uploads nothing. The controller waits until the saved recipe shows in
  `watchAll()` (a save commits in the background), or until the stream ends, for 30 seconds at most
  in total, then cancels its listener, before it uploads the cover, so a picture that came before the save also reaches the recipe. The
  ingredient rows show a check (`RecipeIngredientTile.inStock`) when the Vorrat
  holds the food, and keep no room for it while no line is in stock
  (`RecipeView.anyLineInStock`).
- The nutrition under the ingredients (`RecipeNutritionSection`), on the
  recipe page and in the idea window: the food label of one estimated portion
  ("1 Portion · geschätzt", `RecipeView.portionFacts`, whole kcal and grams),
  and under it "Nährwerte je Zutat". Nothing without an estimate.
- "Nährwerte je Zutat" (`RecipeLineNutritionSection`): a folded row under the
  food label. It shows when the
  recipe's estimate has values per line. Its head row says "Für N Portionen":
  N follows the portion stepper on the recipe page and is the recipe's own
  portions in the idea window. Each row names the food alone
  (`cookLineFoodName`, `inventory`: "Knoblauch" for "2 Zehen Knoblauch",
  "Zitrone" for "½ Zitrone", "Tomaten" for "1 Dose (400 g) Tomaten";
  `RecipeView.lineNutrition`).
- The recipe page reads a line like the Kochmodus (`parseIngredientExactly`,
  `recipes`, which normalizes the line itself; the page does not): "½
  Zitrone", "eine halbe Zitrone", and "zwei Zwiebeln" get their amount. A
  Vorlage's component names are read as written (`parseName`). A line whose amount rounds to 0 for matching ("0,1 g Safran", "1/4
  Zitrone") keeps its text whole.
- The AI estimate of a recipe: `RecipeEstimateRepository` calls the Firebase
  AI template `recipe-estimate-template`; `RecipeEstimateService` runs it in
  the background and saves it on the latest recipe. The Kochbuch page starts
  it for the recipes without a fitting estimate, at most three at once. Failures
  are silent.
- The overview that sorts saved templates into Vorlagen and recipes and marks
  which foods of a Vorlage the Vorrat holds and which lines of a recipe's run
  are assigned.
- Removing a Vorlage or recipe from the Kochbuch, from a long press on its
  card or from the recipe page, and its undo.
- Planning one portion of a Vorlage or recipe for a day, from a long press
  on its card (`RecipePlanFlow`), and its undo.

## Does Not Own

- Template, meal, and Vorrat storage and their mutations (`inventory`);
  the recipe editor saves through inventory's template writer and reads
  ingredient lines with its parser.
- The document scanner (`core/device`).
- The recipe link import and its review (`meal_templates`); the flow after
  it is `RecipeLinkFlow`.
- The shared text holder `PendingSharedText` and the signal of an unreadable
  share (`core/device`), which the scanner's share service fills. That service
  keeps a link into the app, such as a household invite, out of the text.
- The shopping list (`shoppinglist`) and the food pick (`product_search_hub`,
  opened through inventory's `PreparedMealPendingFoodFlow`).
- Asking for and generating the recipe idea (`ai_chef`) and the kitchen
  utensils (`kitchen_utensils`).

## Public UI

- `CookbookPage`: the Kochbuch tab.
- `presentation/widgets/cookbook_cook_actions.dart` (`cookbookCookActions`):
  the actions that the home shell shows in its action panel on the Kochbuch
  tab.

## Rules

- The editor saves only with a name, a portion count above 0, and one
  ingredient line.
- A scan takes up to three pages. The server prompt template
  `ingredient-list-template` (Firebase AI) returns title, servings,
  ingredient lines, and steps; the answer is parsed strictly. A scan fills
  the name only while it is empty, sets the portions when the list names
  them, and appends its lines and steps to the typed ones.

- A saved recipe idea carries its `RecipeEstimate`, with the values of each
  line, and the weight of each line (source `ai`). The card and the recipe page
  show kcal and macros at once, without a second estimate.
- A template with recipe ingredients is a recipe; one without is a Vorlage.
- A recipe is prepared on "Was hast du da?" and cooked on the cooking page
  (`kochmodus`); the card only opens the recipe page. The main button of the
  recipe page has these states:
  - No run: "Vorbereiten" opens "Was hast du da?" for the chosen portions.
  - A run with an open or shopping line: "Weiter" opens "Was hast du da?".
  - A run whose lines are all settled and that has not started cooking:
    "Kochen" opens the cooking page.
  - Any other run: "Weiter" opens the cooking page.
  The button is off without a line to cook and while a Vorlage is being cooked.
  While a line is open, a hint says "Kochen" waits until every ingredient is
  ready or left out. The portions are locked while a run exists.
- A Vorlage's "Kochen" cooks it directly from its recipe page into the pot and
  the "Gekocht" page (`RecipeCookFlow.cook`).
- A line that does not count (`cookLineNotCounted`, in `recipes`) reads "zählt
  nicht mit" and is not counted on the status card.
- The recipe cards show the macro line with coloured numbers (`MacroGrams`,
  `core`).
- The status card shows whenever a run exists. Its title is "Noch N offen"
  while a line is open, else "N im Einkauf" while a line waits for shopping,
  else "Alles bereit"; the running card of "Läuft" says the same ("Noch N
  offen", "N im Einkauf", "Alles bereit"). Under it stand the counts that are not 0: "N bereit",
  "N im Einkauf", "N weggelassen", "N offen".
- A line is "bereit" (check, with what its Vorrat food holds; "300 ml da ·
  200 ml im Einkauf" while the rest of it waits on the shopping list,
  `RecipeLineAssigned.rest`, which counts as "im Einkauf"), "im Einkauf"
  (cart), "weggelassen" (minus, muted), or "offen" (empty circle). A
  line shows the amount the cook set for the run, scaled to the run's portions,
  instead of the recipe's (`own`) when it is "bereit" or "im Einkauf".
- A line state shows only beside the line it was taken from: a cook run keeps
  the text it started with, and another line at that place shows none.
- A recipe plan is one portion of the recipe cooked for the portions chosen
  from the items matched, built by inventory's `buildTemplatePlanEntry` and
  saved without stock. An ingredient without a Vorrat item makes it a reminder
  without kcal ("kcal offen") unless the recipe's estimate fits; accepting it
  later takes the recipe's items then and logs it without deducting stock.
- Removing a template deletes only its document. Its photo stays, because
  Vorrat meals cooked from it keep the same photo reference, and the undo
  saves the same template back.
- A recipe ingredient counts as in stock when its saved Vorrat item, or else
  a name match, is kept in a unit that fits its amount
  (`inventory/application/ingredient_stock_match.dart`, the rule the recipe
  page, plans and open rows share). An item that is not used up counts,
  however much it still holds; once a cook run has an assigned line, the recipe
  page shows what is left of its item for this cooking. An ingredient that names no amount ("Salz")
  fits any item of its name and takes nothing when cooked. A Vorlage food
  counts when an item of its name is not used up. Ignored recipe ingredients
  are left out.
- "Läuft" shows the household's cook runs first, then, under "Aus der
  alten Version", meals that are still in the pot or have open rows and
  have portions left.
- The food weight is the pot on the scale minus the empty utensil. A cooked
  meal without weighing stores no weight and no empty pot weight; a combined
  meal (one without rows) stores the sum of its ingredients when all are in
  grams, unless the cook weighs it instead.
- A Vorlage takes each food's own amount for the portions chosen from the
  Vorrat items it was combined from; what they lack stays an open row on the
  saved meal.
- A plan and a Vorlage's cooking take for an ingredient the Vorrat items the
  recipe saved for it that still fit, else the best fitting match. The recipe
  page offers no pick.
- A saved recipe's ignored ingredients and saved Vorrat items
  (`ignoredRecipeIngredients`, `recipeIngredientAssignments`) are only read
  now: nothing edits them on a saved recipe. The cooking page decides each
  line per run instead.
