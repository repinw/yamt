# Shopping List

## Purpose

Shopping List keeps the household's grocery list: what to buy and how many,
saved favorites, and products that come back on a schedule.

## Owns

- Shopping list items with their favorite and recurrence settings, stored
  encrypted with the household key.
- List mutations: adding and merging products, quantities, moving an entry
  into the cart and back, reverting an addition, and the calendar recurrence
  rules.
- Suggestion filtering, the order of pushed back suggestions (kept on the
  device), and the visible list sections.
- Adding products by name for later features, which skips the ones on the
  list already.
- The shopping list page, its widgets, and its controller.

## Does Not Own

- Inventory stock and the purchase interpretation of a list entry.
- Recipe and cooking ingredient parsing.
- Household membership and the household key.

## Public UI

- `ShoppingListPage` with two slots: `suggestionStrip` over the tiles and
  `planNeedsSection` under the list. Inventory fills both and composes the
  finished page.
- `ShoppingListSuggestions` renders `ShoppingSuggestion` values as a strip
  to scroll sideways and hides products that are on the list and still to
  buy. A tap puts a suggestion on the list; the cross pushes it behind the
  others.
- `ShoppingListPlanNeeds` renders the "Für deinen Plan" block from
  `ShoppingPlanNeedGroup` values, with one add button per food, and an error
  line with a retry when the needs fail to load. `groupShoppingPlanNeeds`
  (application) groups `ShoppingPlanNeed` values by day and meal and drops
  foods that are already on the list.
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
- Finishing the trip removes the entries in the cart.
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
- Every save replaces the whole list in one serialized write. While the user
  is signed out or the household key is not ready, reads return no items and
  writes fail.
