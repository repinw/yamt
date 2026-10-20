# Inventory Feature

Inventory owns food stock, prepared meals, global food matching, receipt aliases,
discard events, and inventory-backed calorie handoff context.

## Owns

- Inventory item domain models, amount parsing, consumption, discard events.
- Household inventory activity events and timeline UI for shared stock changes.
- Prepared meal domain models and mutation workflows.
- Inventory repositories and stores for Firestore-backed inventory data. The
  stores encrypt every document with the household key
  (`householdCipherProvider`); only the fields that queries need stay
  readable.
- Inventory pages, widgets, controllers, and presentation-only helpers.
- Global food item matching and serving suggestion persistence used by
  inventory flows.

## Does Not Own

- Authentication identity or household membership. Inventory consumes auth and
  household public providers for data ownership.
- Calorie log storage and calorie entry editing UI. Inventory builds handoff
  context and delegates persistence to calories flows.
- Scanner capture/review. Inventory may launch scanner public surfaces.
- Product search internals. Inventory may compose product-search public pages
  for manual product lookup.
- Shopping list persistence. Inventory may call shopping-list public operations.

## Public Edge

Other features may consume these public Inventory entry points:

- `InventoryPage`
- `InventoryShoppingListPage` (finished shopping surface with stock suggestions)
- `application/inventory_quick_eat_data_providers.dart` for repository-backed
  quick-eat inventory data used by integrating features, and
  `livePreparedMealProvider`, the one live source of a Vorrat meal by id: the
  stored meal, which every meal page reads.
- `application/inventory_eat_service.dart`: eats a Vorrat item into the
  diary. `InventoryPendingConsumptionStore.stage` reserves the stock (capped
  at what the item holds), `InventoryEatService.log` saves the entry with it
  or hands it to the calorie editor, `logEdited` saves the entry the editor
  returns, and `commit` writes a diary entry together with the item stock it
  takes, for single, combined, and calorie editor eats. A failed eat
  releases its reservation. After a save the service learns the eaten
  serving for the food.
- `application/inventory_entry_delete_service.dart`: deletes any diary entry.
  For an entry that took stock it can give the stock or the portions back,
  and the delete and the stock change are one write through the commit
  stores. Its undo saves the entry and takes the stock again in one write.
  The new stock goes to the Vorrat list at once. The eat flows call no
  service or store themselves; they go through `InventoryItemEatController`
  and `InventoryItemsController`.
- `application/inventory_plan_service.dart`: saves a plan, a diary entry
  for a later day (or an explicit plan today) that takes no stock yet but
  keeps the stock amount it will take. It reports the plan's day to
  `LastPlannedDay`, so the diary opens that day.
- `application/inventory_plan_accept_service.dart`: eats a plan on its own
  day and meal. A Vorrat food takes its stock from a pack of the same food
  (`domain/inventory_plan_pack.dart`: the planned pack, or one with the same
  name and brand in the plan's unit; opened packs first, then the oldest);
  a cooked meal takes its portions. Without stock left the food is logged
  without stock. The plan is deleted first and comes back when the eat
  fails; `undo` deletes the entry with its stock and saves the plan again.
  A reminder (`CalorieEntry.nutritionPending`, a plan of a meal with open
  rows, built with no kcal by `buildConsumedPreparedMealCalorieEntry`)
  throws `InventoryPlanAcceptException.isNutritionPending` while its meal
  still has open rows and `isMealGone` without its meal, instead of
  logging an entry without kcal. Once the meal is filled, a reminder eats
  it, or, without portions left, logs the meal's values without stock.
  A plan of a Kochbuch recipe or Vorlage (`CalorieEntry.bundleSourceTemplateId`)
  is logged without stock; its reminder takes the recipe's Vorrat items
  (the saved ones in a fitting unit, used up or not, else the best match
  that fits) and its planned portions when accepted and throws the same flags while one is missing or
  the recipe is gone.
- `application/ingredient_stock_match.dart`: the one rule for which Vorrat
  items can supply a recipe ingredient, best first: a name match whose unit
  fits the amount, with the recipe's saved unit conversion. A recipe line
  that names no amount ("Salz") takes any item of its name and gives
  nothing when cooked. The recipe page, free cooking (rows with an amount),
  plans, open rows and the Kochbuch cards use it.
- `application/template_plan_entry.dart`: `buildTemplatePlanEntry` builds
  the plan of one portion of a Kochbuch recipe (cooked on paper from its
  assigned Vorrat items, each counted as a full pack) or Vorlage.
- `application/prepared_meal_reminder_plan_service.dart`: keeps a meal's
  plans in step with its rows (reminders while a row is open, the meal's values once
  none is). The meals controller runs it after every change of the rows
  (fill, ignore, unignore, take a food out, edit, undo of an edit); a
  failure there is logged and leaves the saved rows alone.
- `application/inventory_quick_eat_application.dart` for eating prepared
  meals from integrating features. Callers pass the `PreparedMeal` they
  show, so no server read delays the save. The calorie entry commit stores
  read the stock local-first and queue a batch, so eating also works
  offline. Item upserts and activity events also queue their
  batches without waiting for the server. The Diary "eat food" flow sizes a
  new item to the eaten amount before its only write and saves the shared
  catalog product and barcode selection in the background.
- `application/prepared_meal_cooking_service.dart`: creates a Vorrat meal from
  ingredient rows without a saved recipe (`cook`), from a saved recipe for
  the chosen portions (`cookRecipe`), or from a Vorlage's foods with their
  own amounts (`cookVorlage`); rows with an assigned item use it up, the
  others stay open on the meal. The meal stays in the pot
  (`PreparedMeal.inPot`) until `finishCooking` stores its portions (or pieces,
  `PreparedMeal.servedInPieces`), empty pot weight, and food weight.
  `PreparedMealMutationService.weighPot` stores a weighing on the eat page
  (`PreparedMeal.potWeighing`), which `InventoryQuickEatApplication` writes
  before the eat; `PreparedMealEatCalculator` counts grams from it.
  `PreparedMealMutationService.changeWeight` stores the "Gewicht ändern" of
  the meal's detail page: the same weighing, plus the weight of the whole
  meal (`PreparedMeal.finalNetWeight`).
- `application/prepared_meal_template_writer.dart`: adds a cooked meal as a
  cookbook template (`PreparedMealTemplateCopy.asTemplate`) for the "Ins
  Kochbuch" switch of the "Gekocht" step; it throws when the save fails.
- `InventoryItemsController`
- `PreparedMealsController`
- `PreparedMealTemplatesController`
- `PreparedMealSelectionController`
- `InventoryActivityEvent` and `InventoryActivityEventRepository`
- Inventory domain types such as `InventoryItem`, `PreparedMeal`, and
  `InventoryItemEatRequest`
- Repository providers from `data/` when tests or app composition need explicit
  overrides
- `InventoryReceiptCandidatePickerSheet` for scanner/inventory receipt-review
  correction flows.
- `PreparedMealCover` for features that display prepared-meal thumbnails.

Callers should not assemble Inventory internal row/card widgets unless they are
already documented as a reusable presentation surface.

## Public UI

- `presentation/widgets/plan_shortage_reminder_settings_builder.dart`
  (`PlanShortageReminderSettingsBuilder`) gives another feature's surface the
  day-before reminder's on/off and time with their setters, whether the
  system blocks its notifications, and a callback that opens the system
  notification settings. Settings uses it for its rows.
- `presentation/widgets/plan_shortage_reminder_listener.dart`
  (`PlanShortageReminderListener`) wraps the app in `lib/app.dart`: it keeps
  the day-before reminders for missing plan ingredients scheduled through
  `core/device/local_notifications.dart` and, on a tap, offers the missing
  ingredients through `ShoppingPlanNeedsFlow.offer`. Reminder ids are
  `100000000 + yyyymmdd` of the plan day (`domain/plan_shortage_reminders.dart`).
- `presentation/inventory_manual_product_save_flow.dart`:
  `saveManualProductResultToInventory` saves a product picked in the product
  search hub to the Vorrat.
- `presentation/inventory_manual_product_eat_completion_flow.dart`:
  `saveManualProductResultForEatFlow` eats a product picked in the product
  search hub, or plans it on a later day.
- `presentation/inventory_item_eat_flow.dart`: `InventoryItemEatFlow.eat` opens
  the eat sheet for an inventory item, stages the stock from the item the
  caller shows, and logs the calorie entry. `undoPlan` deletes a plan for an
  undo, and `failureMessage` names what failed for an eat failure.
- `presentation/inventory_combined_eat_flow.dart`: `InventoryCombinedEatFlow.eat`
  logs a stock item together with other stock items as one combined calorie
  entry, written in one batch with every stock change.
- `presentation/inventory_template_create_flow.dart`:
  `InventoryTemplateCreateFlow.create` opens the Vorrat in selection mode for
  "Neue Vorlage" in the Kochbuch, asks for the name, and saves the picked
  foods with all of their stock as a cookbook template; the Vorrat stays as
  it is.
- `presentation/prepared_meal_detail_flow.dart`: `PreparedMealDetailFlow.open`
  opens the detail page of a Vorrat meal with its open and ignored rows, the
  x that takes a food out again, and the meal actions.
- `presentation/prepared_meal_gone_flow.dart`:
  `PreparedMealGoneFlow.closeWhenGone` closes a meal page with "Mahlzeit nicht
  mehr im Vorrat" when its meal leaves the Vorrat; every meal page, including
  the Kochbuch's "Gekocht" page, uses it. `closeWhenOutOfPot` closes a meal
  page with the caller's message and snack bar key when its meal leaves the
  pot while the page is open, unless the page saves it itself; the "Gekocht"
  page uses it for a meal cooked on another device. `close` takes an
  optional message and key.
- `presentation/prepared_meal_pending_food_flow.dart`:
  `PreparedMealPendingFoodFlow.fill` finds a food through the food pick
  (`PreparedMealFoodSource` in `presentation/models/`), adds it to the Vorrat
  with the entered amount, and hands its id to the caller.
- `presentation/prepared_meal_eat_flow.dart`: `PreparedMealEatFlow.eat` opens
  the eat sheet for a prepared meal and logs the eaten portions as one bundle
  entry.
- `PreparedMealCover` and the receipt review sheets listed above.
- `presentation/widgets/eat_sheet/`: `InventoryItemEatSheetBody` (the eat
  page for one item, with header overrides, a custom second action, an
  optional trash button ("Aussortieren"), and a selection callback),
  `EatPageScaffold`, `EatPageHeader`, `EatLabelTable`,
  `EatAmountRuler` with `EatRulerMark`, `EatSheetTextField`, `EatWhenMenu`
  with `showEatPlanDayPicker` (the plan day picker of the Planen icons),
  `EatActionCard`, `EatChip`, `EatComponentsList`, `EatCountRow`,
  `EatMealPortionsRow` (the portion counter, with an optional maximum), `EatImageTile`,
  `EatInlineAmountField`, `EatFramedBox`, `EatLabelTitle`, `EatLabelInputRow`
  (one editable row of a food label), `EatTextLink`, `EatMissingValuesHint`
  with `productMissingValuesText` (the line that names a product's missing
  values), `consumedUnitSymbol`, `planSavedMessage` and `formatQuickChipAmount`
  (the amount with a quarter glyph such as "½"; `eat_sheet_l10n.dart`), so later
  features can show and edit foods in the same food label look.

## Rules

- `domain/product_missing_values.dart` is the one completeness check for a
  product: the seven EU label values, and the package size where stock
  matters. A size in pieces counts only with grams per piece (a serving in g
  or ml). Every missing-values hint uses it, also the "Nährwerte
  unvollständig" note of a meal ingredient, and so will the search list.
- A Vorrat meal stores only energy and the macros. Its other nutrients come
  from the label of each ingredient's source item
  (`PreparedMealComponent.nutritionFacts`), scaled like the stored totals.
- `domain/prepared_meal_rules.dart` is the one place that decides what a
  Vorrat meal allows now: eat only when it is out of the pot, has no open
  rows and has portions left; plan when it has no open rows and portions
  left, also as a share of a meal in the pot; ingredients stay editable until
  the first portion is gone. Sheets, the Kochbuch, the diary picker, plan
  accept and the commit store ask it instead of combining the meal's flags.
  `withPortionsTaken` is the one portion change: eating, throwing away and
  taking portions back all go through it. `withWeightLeft` is the one
  change of the meal's weight after "Gekocht": the grams of food left with
  the portions left when the cook weighed (the weight dialog's meal, so an
  eat in between does not move them), and the whole meal scaled from them;
  nutrients and diary entries stay. The weighing on the eat page
  (`withFoodWeighed`) keeps the weight from "Gekocht".
- `domain/prepared_meal_rows.dart` moves a meal's rows: open rows keep the
  meal from being eaten, ignored rows stay on it and count for nothing.
  A food remembers the row it fills (`PreparedMealComponent.openRow`, its
  share of the row when several foods fill it); taking it out of the meal,
  on the detail page or in the editor, opens that row again and gives its
  stock back. Meal totals are always summed from the foods, never patched,
  so taking a food out restores the totals from before it came in.
- A new manual product keeps its pending id until its catalog write
  succeeds (`application/manual_product_catalog_service.dart`); only then the
  barcode is recorded and the Vorrat item points at the catalog product,
  through the Vorrat queue. Offline, the product stays private (#806).

## Providers

- Repository providers live in `data/`.
- Use-case/service providers live in `application/`.
- Controller providers live in `presentation/controllers/`.
- `application/inventory_entry_amount_service.dart` changes the amount of a
  diary entry: items measured in grams or milliliters consume or return the
  difference in the same write as the entry, while items counted in pieces
  keep their stock.
- `provider/` is legacy and should stay empty; do not add new files there.

## Inventory Activity

Activity events are append-only household timeline entries stored under the
active household. They record shared stock facts only: actor, item,
amount, timestamp, and before/after stock. Personal calorie diary data remains
owned by `calories` and is not exposed through the activity timeline.

## Shopping Recommendations

- `domain/inventory_replenishment.dart` aggregates product batches by brand and
  product-name matching. Exact names and sufficiently specific whole-word
  variants such as `Eiweißbrot` and `Eiweißbrot - Proteinkorn` share their stock
  total. Partial words and short generic names do not match. Distinct nonempty
  receipt IDs within 180 days are purchase evidence; manual additions and
  duplicate rows on one receipt do not inflate frequency. Only retained
  inventory records can contribute receipt evidence.
- Remaining amounts are normalized to pack equivalents across all batches.
  At most 0.25 packs with activity in the last 60 days triggers replenishment.
  Empty stock is labeled separately from a small positive remaining amount. Additional
  full batches prevent false low-stock suggestions. Deposits, discounts and
  future entries are excluded. Low stock sorts before purchase frequency.
- `application/inventory_shopping_suggestions.dart` owns the live repository
  input and adapts these facts to shoppinglist's public suggestion model.
- `InventoryShoppingListPage` injects that source and retry action into the
  finished shopping page. Shoppinglist does not import inventory.

## Accepted Dependencies

Inventory currently has explicit dependencies on:

- `auth` and `household` for current data owner resolution.
- `calories` for meal type, calorie entry handoff, and prepared meal calorie
  logging. `application/inventory_calorie_nutrient_details.dart` maps an
  item's label nutrients into the calories `CalorieNutrientDetails` so logged
  entries keep them.
- `shoppinglist` for add-to-shopping-list actions from inventory rows.
- `recipes` for template ingredient parsing.

These dependencies are migration-reviewed. New dependencies should be added only
with a README note and should avoid new cycles.

## Tests

Inventory tests live under `test/features/inventory/`. Controller tests live
under `test/features/inventory/presentation/controllers/`.

## Migration Notes

- Legacy controller files were moved from `lib/features/inventory/provider/` to
  `lib/features/inventory/presentation/controllers/`.
- Manual Riverpod providers were migrated to code-generated providers where the
  feature owned the implementation.
- Hand-written UI `part` files were split into normal widget files. Generated
  `*.g.dart` and `*.freezed.dart` parts remain allowed.
