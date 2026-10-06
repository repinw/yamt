# Domain Glossary

The words the app and its code use for the food a user owns and eats. Code
names are in parentheses.

- **Vorrat** (inventory): the food a household has at home. An item
  (`InventoryItem`) counts pieces or holds an amount in g or ml. A Vorrat
  meal (`PreparedMeal`) is cooked food kept in portions.
- **Tagebuch** (diary, calories): what a user ate, one entry
  (`CalorieEntry`) per food or meal and day. Entries are private to the user;
  the Vorrat belongs to the household.
- **Plan** (planned entry, `PlannedEntryRepository`): a `CalorieEntry` on a
  future day, stored apart from the diary. It takes no stock.
- **Reservierung** (pending consumption, `PendingInventoryConsumption`):
  stock held back for an eat that is not saved yet. It is committed with the
  diary entry or released when the eat fails or is cancelled.
- **Eintrag mit Vorrat-Abzug** (stock-taking entry): a diary entry that took
  stock from the Vorrat. It keeps the amount it took
  (`sourceInventoryAmountToRestore`), so deleting it can give the stock
  back. `InventoryEatService` owns these entries: it saves them together
  with their stock in one write.
- **Rückbuchung** (restore): giving the stock of a deleted or reduced
  stock-taking entry back to the Vorrat.
