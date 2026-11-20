# Shopping List

## Purpose

Shopping List keeps the household's grocery list and the user's private
one: what to buy and how many, where it stands in the shop, saved
favorites, and products that come back on a schedule.

## Owns

- Shopping list items with their favorite and recurrence settings, stored
  encrypted with the household key, and private items stored under the user
  encrypted with the user's data key.
- The product catalog (shelf and icon per known product, German and
  English) and the shelf chosen per product in the household.
- The list import: reading a pasted or photographed list with the
  `shopping-list-import-template` AI template and the review before adding.
- List mutations: adding and merging products, quantities, moving an entry
  into the cart and back, reverting an addition, and the calendar recurrence
  rules.
- Suggestion filtering, the order of pushed back suggestions, the list order
  and the list shown (household, private, both), all kept on the device.
- The list page view: the entries of the list shown, grouped by shelf or
  sorted by name, with taps not saved yet, the cart, the saved products, the
  counts per list and the finish summary. Widgets only render it; the tiles
  are built as they scroll into view.
- Adding products by name for later features, which skips the ones on the
  list already.
- The shopping list page, its widgets, and its controller.

## Does Not Own

- Inventory stock and the purchase interpretation of a list entry.
- Recipe and cooking ingredient parsing.
- Household membership and the household key.

## Public UI

- `ShoppingListPage` takes the `suggestions` of a later feature as
  `ShoppingSuggestion` values, and a `suggestionsError` slot for the time
  they failed to load. Inventory passes its suggestions, fills the slot with
  `ShoppingSuggestionsRetryButton` and its own retry, and composes the
  finished page. The page shows the
  suggestions as a strip over the tiles and offers them as hits in the add
  sheet. The finish page offers no receipt scan; the receipt is imported
  later in the inventory.
- `shoppingSuggestionsWithPlan` (application) puts what the plans need in
  front of the suggestions, once per food, with `plannedFor` set to its first
  meal. `groupShoppingPlanNeeds` (application) groups `ShoppingPlanNeed`
  values by day and meal and drops foods that are already on the list.
- `ShoppingHeaderTool` (presentation/widgets) is the header tool that opens
  the shopping list. The diary, inventory, and cookbook_new headers use it.
  A badge shows the count of open entries on both lists, "99+" from 100.
  With `onlyWithOpenEntries` it hides while nothing is open.
- `showShoppingListImport` opens the list import.
- `ShoppingPlanNeedsFlow.offer` asks whether a plan's missing foods go on
  the list, each one tickable, and adds the ticked ones; cookbook calls it
  after planning a recipe. With `offerNeverAsk` it adds a "Nicht mehr fragen"
  button and returns whether the user picked it; inventory's day-before
  reminder turns itself off then.

## Rules

- An entry is to buy, in the cart (done), or archived. An entry in the cart
  keeps the quantity it was asked for. Only entries to buy count as "on the
  list" for suggestions, plan needs, and additions from other features.
- Adding a product that is to buy puts the quantity on top. Adding one that
  is in the cart or archived brings it back with the new quantity alone. A
  due schedule does the same with the schedule's quantity.
- Finishing the trip removes the entries in the cart of the list shown.
- A new entry goes on the private list only while the private list is shown;
  in "both" it goes to the household. Adding merges only within the same
  list.
- A shelf chosen for a product wins over the catalog; a product neither
  knows sits under "other", shown as not assigned.
- The add field reads a leading count up to 99 as the quantity ("2 Milch");
  a number in front of a unit ("500 g Hack") stays part of the name.
- A suggestion pushed back comes after every suggestion that was not, the
  one pushed back longest ago first. The order is kept on the device, not
  in the household.
- Removing or clearing a saved product archives its entry and keeps the
  favorite and the schedule. Re-adding reuses the same entry and never
  duplicates an active item.
- Recurrence uses a local calendar interval of 1 to 365 days, a quantity of 1
  to 999, and a first due date. Due entries reactivate once at load, on
  resume, or on the page's minute tick. Missed intervals advance to the next
  future date without a backlog. Active quantities stay unchanged.
- Configuring a schedule and applying it when already due is one serialized
  save. A failed save rolls both back for a later retry. Widgets only submit
  the settings; activation does not depend on the widget staying mounted.
- Every save replaces the whole list in one serialized write, the household
  part and the private part each. While the user is signed out or the
  household key is not ready, reads return no items and writes fail.
  Without the user's data key there are no private items, and a save that
  holds one fails.
