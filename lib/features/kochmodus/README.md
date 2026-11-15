# Kochmodus Feature

Kochmodus is the cooking mode: one cook run from a recipe or free cooking.
A recipe run first asks "Was hast du da?" on its own page, one ingredient at
a time; the cooking page has the steps Töpfe, Kochen, and Portion. It is the only way to cook a recipe
or a meal without a recipe.

## Owns

- Domain: cook durations, voice commands, the pot split, the meal name,
  whether a name is a food (`cookNameIsFood`, `cookFoodWords`), and the fill
  order over Vorrat items (`fillInOrder`). Three readings of a line's text live
  elsewhere, because other features read them too: `cookLineNotCounted` and
  the reading form of the text (`normalizeCookLineText`, pinch, scoop, a line's
  own measure) in `recipes`, and the food a line names (`cookLineFood`,
  `cookLineFoodName`) in `inventory`.
- Application: the one reader of a line (`parseKochmodusLine`) and its text
  (`cookLineLabel`), line amounts and the part of a Vorrat item a line needs,
  takes from the Vorrat, what is left of a food for a line (`cookLineStockLeft`),
  what the food pick gets for a line (`cookPickNeed`, `cookSpoonWeight`, `cookSpoonGuessed`), the weight of a line (`cookLineWeightOf`), the recipe's rough weight of a line without an
  amount, the recipe source (the Kochbuch recipe a run cooks),
  the finish checks, the start, pause, finish, and discard services, and the
  timer alarm reconcile.
- Presentation: "Was hast du da?" (`KochmodusAssignPage`): the card of the
  line to answer with its answers, the list "Alle Zutaten" with a
  state badge per row, the line under the card that says what "Hab ich"
  entered, and the finished card. The change sheet (`KochmodusChangeSheet`)
  of the Portion rows. The cooking page (`KochmodusPage`)
  with its steps Töpfe, Kochen, and Portion (one row per line), the done view
  "Guten Appetit!", the controller both pages share, the controller that
  starts, extends, and stops the timers (`KochmodusTimerController`), and the
  timer alarms.
  "Alles bereit" and "Guten Appetit!" show the macros of the meal, and "Alles
  bereit" has the food label of one portion under the card
  (`KochmodusNutritionLabel`). The done
  view takes one serving's values and its kind (portion, piece, or can) from
  the view model (`KochmodusDone`, `KochmodusServing`).
- The guide step (`KochmodusGuideStep`) shows under an instruction the lines it
  names with their amounts (`KochmodusStepFoods`), and under its times the
  hint why a timer may not ring as it should (`KochmodusTimerHint`).
- The step Töpfe: a pot the cook adds there is chosen at once; one that is gone
  again after the undo of adding it is not.
- The amount sheet of a line (typed amount, "Vorhandenes" and "Rezept"
  presets), the question "Wie viel nimmst du?" (`KochmodusTakeFlow`,
  `KochmodusTakeSheet`), and the Vorrat picker "Welches nimmst du?": the
  whole Vorrat, name matches on top, search, and the order and receipt groups
  of the Vorrat's saved sort preferences, which `inventory` owns.

## Does Not Own

- The cook run document, its repository, and its changes. `recipes` owns them.
- Stock writes and the cooked meal batch. `inventory` owns them.
- The recipe page and its buttons that lead here (`cookbook_new`).
- The food screens "Welches ... hast du?" (`product_search_hub`) and the
  amount page that asks how much is at home (`inventory`).

## Rules

- A service keeps itself alive until its write is issued.
- A write of the run that the server rejects later (`CookRunRepository.rejected`)
  does not end the page: what the cook sees stays as a draft that the next
  change stores again, and the page says the cooking could not be saved.
- Finish writes the Kochbuch recipe before the batch. Each recipe line says
  what this cooking used: the cook's amount, or the takes of a line whose
  text names no amount.
- A run reserves Vorrat through its takes (`recipes` reads them as
  `reservations`); nothing leaves the Vorrat before "Fertig".
- A weighed line sets the take when all its items are kept in g or ml; for
  items in pieces or whole packs the weight is only a record. A weight is a
  fact: it is limited by the run's own other lines, not by other runs'
  reservations, and what the items cannot hold goes onto the last item so the
  stock check names it.
- The guide shows under a step the lines it names, each with the amount the
  cooking list says (`KochmodusView.guide`, `KochmodusGuideLine.foods`,
  `KochmodusStepFood`; `cookLineTextParts` splits a line into amount and
  food). A step names a line when one of the line's food words
  (`cookLineFoodName`) stands in it as a whole word, in singular or plural
  (`cookStepNamesFood`), or ends a compound of it as its head ("Bohnen" names
  "Kidneybohnen"; not a two-letter word, nor "braten"); only the words before what the food is for count
  (`cookFoodBeforePhrase` in `inventory`: "Olivenöl" of "Olivenöl zum Braten",
  so "braten" does not name it); articles and small words ("von", "aus",
  "from"; "Saft aus 1 Zitrone" stays whole), kind words, "Bio",
  and a word that only starts a longer one ("Milchreis" for "Milch") never
  count, and the last part of a hyphenated word is a word of its own. A line the cook left out is skipped; a
  line that does not count (a pinch of salt) stays.
- While a pot waits for its weight and that is the first reason on "Fertig
  gekocht", the main button says "Topf wiegen" ("Töpfe wiegen" for several) and
  opens the weighing of that pot (`KochmodusPortionView.potToWeigh`,
  `KochmodusMealBox.weigh`, the same sheet as the field "Topf mit Essen").
  Any other first reason keeps the button off.
- The food label under "Alles bereit" shows one portion
  (`kochmodusPortionLabel`; `KochmodusView.portionLabel`), `null` while a take
  has no item or lacks energy or a macro. The card's energy and macros are the
  same numbers (`kochmodusPortionMacros`, `KochmodusView.perPortion`).
- g and ml count 1:1 on the cooking page only.
- A line in spoons (EL, TL) takes a standard spoon (`cookSpoonWeight`): the
  line's own conversion from the recipe, else 15 g per EL and 5 g per TL.
  `cookTakeFor` and the picker's offers apply it when takes are counted, and
  `cookPickNeed` hands the food pick the need by weight (also for "Ändern" on a
  new food). So "Egal, irgendeins" and the picker serve a spoon
  line from any food kept in g or ml. The weight is never stored on the run and
  never written into a recipe. A scoop without a weight ("2 Tassen Reis",
  "ein Löffel Öl", "eine Handvoll Nüsse") still waits.
- Only EL and TL are spoons (`cookLineAmountKind`). Their weight is always
  estimated (`cookLineWeightOf`): a spoon is never a weight, also with the
  recipe's own weight of one. It reads "≈" and counts in "Bei N Zutaten haben
  wir das Gewicht geschätzt". Every other measure (Tasse, Kelle, Handvoll,
  Zehe, Bund), also with the recipe's weight, counts like pieces. On a food
  kept by weight (`cookKeptByWeight`) a spoon and every other measure stand
  under "Noch zu wiegen".
- A guessed weight (`cookTakeGuessed`: a level spoon, `cookSpoonGuessed`, or a
  line in pieces, a measure, or without an amount that counts and takes from a
  food kept by weight) takes at most what is there. Its line is short only
  when the food has nothing left (`shortBy`); the picker's offer needs no more
  than is left (`kochmodusPickerOffers`). A guessed spoon with a part ("1/2 TL
  Zimt") and nothing left reads as short, not as waiting for a weight. A
  guessed weight whose stored take is above what is left (another cooking took
  stock since) is a card of its own (`toAnswer`) and offers "Nur … nehmen"
  with what is there, never "Kaufen" (`kochmodusGuessedTakeOnly`). A guessed
  line (a spoon, pieces, a measure, or without an amount) whose stored take is
  0 (assigned by an older build) keeps waiting for a weight: the view follows
  the stored take, and nothing rewrites takes on load.
- A line that does not count is no estimate: it is neither in
  `KochmodusView.estimated` nor in "Noch zu wiegen". A line whose food left the Vorrat (`entryMissing`) is neither an
  estimate nor under "Noch zu wiegen"; its cooking row says "Eintrag fehlt"
  and offers no "Wiegen". A missing weight is no estimate either:
  `estimatedCount` counts only estimated weights.
- An assigned line that takes nothing and waits for a weight
  (`KochmodusLineView.weighWhileCooking`) says "Gewicht fehlt" as a warning on
  its row, with no check badge (card: "Gewicht fehlt: beim Kochen wiegen"),
  not "Bereit".
- A take cut for too little stock is filled up again when "Zuweisen" opens
  (`KochmodusController.open`) and on "Kochen" (`toPots`;
  `cookRunOpened`, `cookRefillCut`, `cookRefillLine` in `cook_refill.dart`): a line that the cook did not weigh and that takes
  something takes again from its own items in their order, and only when that
  gives no item less and one more. A take is never cut there; weighed lines
  and lines that take nothing stay as they are.
- Every text that says how much of a food is there for a line (card, entered
  line, row, "nur … da") says what is left for this line in the unit the food is
  kept in (`cookLineStockLeft`, `kochmodusThereText`), never in spoons. The
  confirmation under the card says it for the line's own food
  (`KochmodusView.stockLeftOf`), not for all foods of the line.
- Amounts in the food's unit use the number format of the locale ("2,5 Stk.",
  "1.250 g"), with a no-break space. An estimated weight is said in the unit
  the food is kept in (`kochmodusWeightText`): "≈ 20 ml" for a food in ml,
  "≈ 20 g" for one in g or pieces. Only an estimated weight in g or ml reads
  "≈"; a count in pieces ("3 Eier") is exact and has none. The card, the cooking list, and the
  confirmation of a new food say it the same way
  (`kochmodusItemAmountText`, `kochmodusWeightText`).
- A line keeps every chosen item that can fill it (`cookTakesFor`). A take of 0
  only holds an item for the next refill: it is never named or pictured
  (`cookNamedItems`), never counted as a food, and writes nothing at finish.
- A food the Vorrat holds already is taken from there: a hit, "Aus dem Vorrat
  nehmen", or a scanned pack that is in the Vorrat. It is never a second item
  and the flow never removes or deletes it. A new food goes into the Vorrat
  first (one full pack, the amount the cook typed, or exactly the line's need
  for an estimated one); the line takes its need from it, capped by that
  stock, and its other items fill only what is still needed (`assignFound`,
  `cookTakesFor`). Only a food that is new to the Vorrat counts as added.
- The app never decides which Vorrat food a line means and never says from a
  name whether the Vorrat has a food: the cook picks. The open card of a line
  that counts has no hint about the Vorrat, and a guessed weight is never shown
  as a fact.
- "Hab ich" (`KochmodusLineAssignFlow.have`) opens the Vorrat picker
  ("Welches nimmst du?") whenever the Vorrat holds a food, and never takes one
  by itself. Only an empty Vorrat opens the product search, which starts with
  the line's whole food name (`cookLineFoodName`: no amount, measure, bracket
  addition, or small word before a capitalized one) and gets the line's need by
  `cookPickNeed` (`PreparedMealPendingFoodFlow.fill(need:, onTake:,
  heldItemIds:)`). The held foods (`kochmodusHeldItemIds`: nothing is left for
  the line) go to the search as `heldItemIds`; it neither offers nor takes
  them, so their product goes in as a new pack. A Vorrat food taken there is
  assigned with `assignItems`, the line's other takes after it. The picker's
  "Etwas anderes suchen" opens the search too.
- The picker shows the whole Vorrat at once: the foods whose name matches the
  line under "Passt vielleicht", then every other food under "Alles im Vorrat".
  Without a suggestion only the second group shows, without its title. The
  search filters both groups. Only a suggestion says what it lacks. Every food
  with nothing left for the line, suggestion or not, reads "verplant", or "für
  {cooking} verplant" when another cooking with a name holds it
  (`KochmodusPickerItemRow`). A line without an amount holds no item
  (`KochmodusOffer.held`): every food can be chosen, also one that another
  cooking planned completely. "Etwas anderes suchen" stays in sight under the
  list, also while the cook searches; only the head and the list scroll.
- A tap in the picker takes the food. The sheet closes when the picks cover
  the need (`kochmodusPickerStillMissing`); else it stays with "Es fehlen noch
  {amount}." and "So lassen". One food covers a line that is weighed while
  cooking (`KochmodusView.toWeigh`, such as "1 Zwiebel" on a food kept in g)
  as soon as it has something left; its offer takes at most what is there.
- "Anderes nehmen" (the "Hab ich" of an assigned line) opens the picker with
  nothing tapped, and the food the cook taps replaces the line's foods. A pack
  found in the search, or a Vorrat food taken there, replaces them too
  (`assignFound(alone:)`). "Zweite Packung" (`KochmodusLineAssignFlow.pickMore`)
  opens the picker with the line's foods tapped, so a new one adds to them,
  and is the only way that keeps them on the search path
  (`KochmodusFoodSearchFlow.find(keep:)`). The search flow asks "Wie viel
  nimmst du?" with the cooking as it is after the search; when the page is gone
  meanwhile, the flow stores the pick with the recipe's amount.
- After one picked food, and after "Aus dem Vorrat nehmen", the cook is asked
  "Wie viel nimmst du?" (`cookTakeAsk`, `KochmodusTakeFlow`,
  `KochmodusTakeSheet`) when the line's amount counts in the unit the food is
  kept in (`cookNeedInItemUnit`), the food holds more than the line needs, and
  at most as much would be left as the line takes (400 g of 500 g asks; 200 g
  of 1 kg and 3 of 10 eggs do not). The answers: "{n} · wie im Rezept", "Alles ·
  {there}" (the line's own amount for this cooking is all that is there), and
  "Andere Menge" (the amount sheet). Closing the question keeps the line's
  amount. After an own amount the question offers the recipe's amount again:
  "… · wie im Rezept" puts the line back on it (`KochmodusTakeAmount` with no
  amount); a line whose text names no amount offers its own amount without
  that suffix. A weighed line, a rough need, and several picked foods ask
  nothing. The sheet scrolls on a small screen and with large text. The pick
  and the answer are one change (`assignItems(own:)`, `assignFound(own:)`), so
  a failed write never leaves the food with the old amount. A pack from the
  search or a scan asks the same question under the same rule, when the line
  takes that one food alone.
- A said weight lands by `cookNameIsFood` (head word of a compound or a part of
  the same food), kept in Kochmodus; the shared inventory matcher stays as it
  is for other callers. The picker scores the line's name too, so a name match
  stays on top where the shared rule has no amount to fit.
- Every read of a line goes through `parseKochmodusLine`, so row, takes,
  booking, and shopping list agree. It never changes what is stored. The
  shared parser (`parseIngredientExactly`, `recipes`) normalises the text
  itself, as does every other caller of it, so the recipe page, plans and
  shopping read the same amount.
- A recipe line whose text names no amount gets the recipe's rough weight of
  the line (`CookRunLine.roughWeight`) when the run starts, for the base
  portions. Until the cook sets an amount, the line needs that weight scaled to
  the portions, shown as "≈ 20 g" (`cookNeedIsRough`). A rough need never makes
  a line "Zu wenig da". A piece line without a conversion of its own ("3
  Eier") gets one piece's weight from the recipe's estimated weight of the
  line divided by its count. A rough weight is accepted only in g or ml
  (`CookRoughWeight`, `recipes`).
- A line that does not count in the nutrition (`cookLineNotCounted`: a recipe
  mark, a pinch measure such as "Prise" or "Msp.", or only salt, pepper or
  water, also with a kind word such as "Schwarzer Pfeffer", "Grobes
  Meersalz", or "Warmes Wasser"; "Schwarzer Tee" counts) starts left out: the start service sets it to `LineIgnored` before
  the cook is asked. "etwas Öl" and "nach Geschmack" are asked like any line.
  Every page says such a line "zählt nicht mit", without a strike-through,
  also when the cook left it out. Only another line the cook left out reads
  "weggelassen" and is struck through.
- Only a line with the origin recipe scales with the portions. A typed or said
  line reads at 1/1.
- A piece line keeps its exact quantity (`exactQuantity`): a kept-in-pieces item
  takes the part of a piece, a whole-count item takes at least 1. A recipe
  that needs less than a piece of an item kept in pieces with a piece weight
  takes part of that piece (`cookPieceWeightOf`).
- Every line reaches the meal or waits: an assigned line that takes nothing
  counts as open on "Was hast du da?" (`KochmodusView.toAnswer`) and blocks
  "Fertig". Only a line whose items are all kept in g or ml is told to
  weigh; any other is told to pick another food. A line with no readable need
  blocks only when it starts with a counted amount; pinches, lines without a
  number, and lines that need only a rough weight do not. A scoop out of a pack (`cookTextScoop`: Tasse, Löffel,
  Handvoll) reads like a spoon: it shows and scales but takes no pieces.
- The cook's amount on a line whose text names no unit stores its unit
  (`CookRunLine.amountUnit`), so it stays when the line leaves its item.
- The Portion rows (`KochmodusPortionLine`) edit, remove with undo, and
  restore a line; their assignment goes through the change sheet and never
  offers the shopping list. A row keeps the measure word of its line ("5 Zehen
  Knoblauch") and drops a second line that only repeats the food's name
  (`kochmodusNamesItsFood`).
- "Was hast du da?" asks one line at a time on a card: the first line of
  `KochmodusView.toAnswer` (the open lines, then the short ones and those that
  take nothing and that a weight cannot help). A recipe line answers one of
  "Hab ich", "Kaufen", and "Weglassen"; the answer is stored at once. After
  an answer the next line takes the card, unless the answered line still needs
  one. A tap on a row of "Alle Zutaten" puts that line on the card until the
  cook answers or closes it. The "+" in the top bar adds a line
  (`KochmodusAssignPage.addLineKey`). A line without an amount and without a
  rough weight shows "Menge eintragen".
- The line `KochmodusEnteredCard` under the card says what "Hab ich" entered,
  until the next answer. It shows when the line takes something of the food
  or, for a new food, holds it without being able to take from it yet
  (`KochmodusLineView.confirms`): then it says "Eingetragen. Die Menge fehlt
  uns noch." and "Ändern" opens the amount page. For a food the line takes
  from it shows the food and "{pack} eingetragen. Wir nehmen {need}
  davon, {rest} bleiben." (a new pack), "... Wir nehmen alles.", "Werte
  geschätzt. Wir nehmen {need}." (estimated). A line under "Noch zu wiegen"
  gets "{pack} eingetragen. Gewogen wird beim Kochen." for a new food, and
  never a guess as a fact: an estimated weight reads "≈" ("Wir nehmen ≈ 3 g
  davon"). For a Vorrat food it says "Aus
  dem Vorrat. Wir nehmen {take} von {there}." when the line's amount counts in
  the food's unit, "Aus dem Vorrat. {there} da. Gewogen wird beim Kochen." for
  a line in `toWeigh` that is neither short nor without anything left of the
  food, else "Aus dem Vorrat. {amount} da.". "Ändern" on a new food opens the amount
  page (`PreparedMealPendingFoodFlow.recount`) and lets the line take again;
  on a Vorrat food it puts the line back on the card. The card keeps room for
  two hint lines, so the answers stay in place from line to line. A rough need
  reads "≈ 3 g" on one line.
- A line is short (`KochmodusLineView.shortBy`) when it is assigned and its
  items hold less than it needs in its unit. A line that follows a weight, needs
  only a rough weight or a part of a unit, or misses an item is never short. A
  short line counts as open: it keeps the main button waiting (`openCount`).
  It offers "N kaufen", "Zweite Packung" (the picker with the line's items
  picked), and "Nur N nehmen" (only while something is there).
- `buyRest` sets the line's own amount to what is there and adds an extra
  shopping line (`cookRestLineId`, in `recipes`) with the rest, in place of an earlier one. With
  nothing there, the whole line goes shopping.
- "Bereit" notes "Nur X" (the cook takes less than the recipe says), "Rest
  steht auf der Einkaufsliste" (`restOnList`), and "≈ N g" for an estimated
  weight.
- The change sheet ("Zutat ändern", or "Was hast du da?" for an open line;
  the Portion rows open it) offers "Hab ich", "Kaufen", and "Weglassen", each once. It leaves out "Kaufen"
  in free cooking, for a line that came in while cooking, for a line already
  on the list, and on "Portion" (`canShop` false).
- Once nothing is left to answer the card is `KochmodusReadyCard`. With
  lines on the shopping list: "Fast alles da" and "Erst einkaufen", which
  puts them on the shopping list, pauses the run, and closes the page with a
  snack bar "Einkaufsliste"; any household member can go on. Else "Alles
  bereit" with "Pro Portion · ≈ … kcal" and the label headed "Portion ·
  geschätzt" while a line is only estimated (`KochmodusView.estimated` is not
  empty), "Mit Anleitung" when the recipe has instructions, and "Kochen",
  which stores the step Töpfe and replaces the page with the cooking page.
  "Später" beside the progress and under the card only closes the page; the
  run keeps its takes.
- Back from the shopping, the shopping lines, the rest lines too, are open
  again and the page says so while a line is open.
- A line in spoons, pieces, a measure ("Zehe", "Bund") or without an amount
  that takes from a food kept in g or ml has only a guessed weight
  (`CookLineAmountKind`, `CookWeightEstimated.toWeigh`), also with the
  recipe's piece weight, until the cook weighs it or sets an amount in g or
  ml. It reads "≈ … geschätzt".
- `KochmodusView.toWeigh` holds the assigned lines whose weight is missing or
  only such a guess. "Noch zu wiegen" lists it under every guide step and on
  the cooking list. Not in it: a food kept in pieces with its own
  piece size, a line that does not count, and a line whose food left
  the Vorrat. "Ansehen" on "Portion" lists `KochmodusView.estimated`, not a line
  that weighing cannot help: first the lines without a weight under "Noch zu
  wiegen" (`KochmodusView.unweighed`), then the estimated ones under "Bei N
  Zutaten haben wir das Gewicht geschätzt" (`KochmodusView.guessed`). With one
  kind only, one title shows.
- "Bei N Zutaten haben wir das Gewicht geschätzt" counts only estimated
  weights (`KochmodusView.estimatedCount`, the length of `guessed`). While none
  is estimated and a weight is missing, the row says "Noch zu wiegen"
  (`KochmodusEstimatesSheet.titleOf`). The row "Bei N Zutaten … / Ansehen" sits
  in the list under the nutrition; the foot holds only the reason line and "In
  den Vorrat legen". The sheet's note is `kochmodusEstimatesNote` ("Wiegen ist
  freiwillig"); while a line without a weight takes nothing it is
  `kochmodusToWeighNote` when no estimated line is listed, else
  `kochmodusEstimatesMustWeigh` ("Zeilen ohne Gewicht musst du wiegen").
- The reason why "In den Vorrat legen" waits is a line above the button
  (`KochmodusPortionStep.blockKey`); the button keeps its label. Counting
  without a pot says "Noch keine Zutat aus dem Vorrat" (no line takes from the
  Vorrat). With two pots a meal's label carries the name the meal has now
  (`KochmodusMealBox.draftOf`).
- A meal in pieces never waits for the pot's weight
  (`CookPotUnweighed`): its field says "{pot} mit Essen (g) · freiwillig".
- In the guide a tap on a single time starts the timer at once, unless a timer
  of that name still counts (`cookRunWithTimer`); after "Stopp" or once it
  rang, a tap starts a new one; a span of times
  asks which end in the timer sheet (`KochmodusActionFlow.startTimer`). The
  hint that notifications are off or that Android may ring the timer late
  shows under the times of a step with "Erlauben" (`KochmodusTimerHint`), as
  in the timer sheet. The title over the lines added while cooking says
  "Gerade dazu · wird beim Portionieren geklärt" while one is open, else
  "Gerade dazu".
- Timers start, extend, and stop through `KochmodusTimerController` (one per
  target, `kochmodusTimerControllerProvider`), each as one change of the run
  through `KochmodusController.change`. The edits of a draft wait for the edit
  that stores the run. A spoken "Timer 5 Minuten" and the Timer button name the
  timer "Timer N" (`KochmodusActionFlow.freeTimerName`), not the step label.
- The lines said or typed while cooking, for "nein", live in
  `KochmodusSaidController` (held by `KochmodusController`), so "nein" works
  after a switch of view or tab. "nein" undoes the last one only while its line
  is as speaking left it; else it drops that one and goes on to the one before. Stopping a timer or removing a line that is gone already is
  no error and writes nothing.
- A change that changes nothing writes nothing (`CookRunRepository`).
- Known gap: "Schätzung ändern" on an estimated weight stores a weighed
  weight, so the line reads "gewogen" afterwards.
- "Zurück" on the first guide step shows the tab "Töpfe".
- `AppRoutes.homeCook` opens `KochmodusAssignPage` for a recipe; its run is
  stored with the first answer. A run with an open or shopping line that is not
  from cooking opens there from "Läuft" and from `AppRoutes.homeCookRun`
  (`CookRun.needsAssigning`). Free cooking has no assigning.
- "In den Vorrat legen" ends the run in one batch: stock, one meal per pot, and
  the run's deletion. The done view says "Guten Appetit!", one sentence per meal
  (portions, pieces, or cans) with the macros per portion, piece, or container
  of each booked meal, "Das Rezept steht jetzt auch im Kochbuch." for
  free cooking saved as a recipe, "Jetzt essen", which opens the Vorrat page of
  the first meal (`AppRoutes.homeInventoryMealPath`), and "Zum Kochbuch".
- Finish keeps an added item while any line holds it, also with a take of 0,
  and keeps it when another run takes it or its stock changed; the rest of the
  item stays in the Vorrat. Discard deletes every added item that is unchanged
  and not taken by another run.

## Public UI

- `CookTimerAlarmListener`: wraps the app in `lib/app.dart`. It schedules the
  notifications of the cook timers this device started, rings them as an alarm
  on Android (through the system's alarm clock, also on a phone set to vibrate
  or silent, with a silent countdown in the tray until then), and opens the run
  on a tap.
- `KochmodusAssignPage` is reached by the route `AppRoutes.homeCook` (a
  recipe, optionally with its portions).
- `KochmodusPage` is reached by the routes `AppRoutes.homeCookRun` (a run) and
  `homeFreeCooking` (no recipe).
