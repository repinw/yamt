# Home – acceptance criteria

Criteria for the bottom bar and the tab headers (issue #1002). The diary page
header and the meal header are in `lib/features/diary/CRITERIA.md`.

Mocks: `Leiste2.dc.html` (bottom bar 2b), `Schnell-D.dc.html` and
`Schnell-D-Tabs.dc.html` (variant D, tab headers). Where a mock and issue
#1002 disagree, the issue wins.

## Untere Leiste

### K1 – Four tabs in normal case
Source: issue #1002; mock Leiste2.dc.html.
Given: I am in any tab.
When: I look at the bottom bar.
Then: it shows the four tabs "Tagebuch", "Vorrat", "Kochbuch", "Fortschritt" in this order, written in normal case (not "TAGEBUCH").

### K2 – The bar floats as a capsule beside its own button
Source: issue #1002; mock Leiste2.dc.html; user decision 2026-11-19 (variant 2b).
Given: I am in any tab.
When: I look at the bottom bar.
Then: the four tabs lie in a floating capsule; the selected tab has a soft background and a lime icon; a separate lime button sits to the right of the capsule.
Phone only: how floating, soft and lime look on the screen.

### K3 – The lime button carries a plus and the tab's word
Source: issue #1002; mock Leiste2.dc.html; user decision 2026-11-19 (variant 2b).
| Selected tab | Word under the plus |
| ------------ | ------------------- |
| Tagebuch     | Essen               |
| Vorrat       | Hinzufügen          |
| Kochbuch     | Kochen              |
| Fortschritt  | Erfassen            |

### K4 – The lime button keeps its size for every word
Source: issue #1002; user decision 2026-11-19 (variant 2b).
Given: I switch between the four tabs.
When: the word on the lime button changes from "Essen" to "Hinzufügen", "Kochen" or "Erfassen".
Then: the button has the same width and height in all four tabs.

### K5 – The lime button opens the tab's actions
Source: issue #1002.
Given: I am in a tab.
When: I tap the lime button.
Then: the actions of that tab open, the same ones the plus button opens there today.

## Köpfe der Tabs

### K6 – Menü button top left in every tab
Source: issue #1002; mocks Schnell-D.dc.html, Schnell-D-Tabs.dc.html; user decision 2026-11-19.
Given: I am in Tagebuch, Vorrat, Kochbuch or Fortschritt, also when the Vorrat holds no food at all.
When: I look at the top left of the page.
Then: the menu icon shows with the word "Menü" under it, written in normal case (not "MENÜ").

### K7 – The Menü button opens the same side menu from every tab
Source: issue #1002; user decision 2026-11-19 ("lass Menü wie es ist").
Given: I am in Tagebuch, Vorrat, Kochbuch or Fortschritt.
When: I tap "Menü".
Then: the side menu opens, unchanged from the one the diary opens today.

### K8 – Where Einkauf shows in the headers
Source: issue #1002 ("Ist der Einkaufszettel leer, steht Einkauf nur im Vorrat"); user decisions 2026-11-19 ("Fortschritt braucht keinen Einkauf"; "wenn kein Einkauf im Warenkorb ist, dann wird es nur auf Vorrat angezeigt"); user decision 2026-11-20 (ticked items).
"Empty" means: no item that is not ticked off; a list whose items are all ticked off (in the cart) is empty.
The Tagebuch row holds for today's date; on another day see diary R4.
| Tab         | Shopping list has open items | Shopping list is empty |
| ----------- | ---------------------------- | ---------------------- |
| Tagebuch    | Einkauf shows                | no Einkauf             |
| Vorrat      | Einkauf shows                | Einkauf shows          |
| Kochbuch    | Einkauf shows                | no Einkauf             |
| Fortschritt | no Einkauf                   | no Einkauf             |
| Tagebuch, 3 items all ticked off | — | no Einkauf          |
| Kochbuch, 3 items all ticked off | — | no Einkauf          |
| Vorrat, 3 items all ticked off   | — | Einkauf shows, no number |
| Vorrat holding no food at all    | Einkauf shows | Einkauf shows, no number |

### K9 – Einkauf opens the shopping list
Source: issue #1002 ("Im Vorrat ist er schon heute da, ins Tagebuch und ins Kochbuch kommt er neu"); user decision 2026-11-19 (shopping list in quick reach).
Given: Einkauf shows in the header of Tagebuch, Vorrat or Kochbuch.
When: I tap it.
Then: the shopping list opens, the same one Einkauf in Vorrat opens today.

### K10 – Einkauf stands rightmost in the header
Source: issue #1002; mock Schnell-D-Tabs.dc.html; user decision 2026-11-19.
Given: Einkauf shows in a header.
When: I look at the tools in that header.
Then: Einkauf is the last tool on the right; in Vorrat it stands after "Verlauf".

### K11 – Einkauf shows the number of open items
Source: issue #1002; mocks Schnell-D.dc.html, Schnell-D-Tabs.dc.html (badge "7"); user decision 2026-11-19 ("das ist aber gut"); user decision 2026-11-20 (no "0", "99+").
Open means not ticked off.
| Open items on the list         | Badge on Einkauf |
| ------------------------------ | ---------------- |
| 0 (empty, or all ticked off)   | no badge, never "0" |
| 1                              | 1                |
| 7                              | 7                |
| 99                             | 99               |
| 100                            | 99+              |
| 250                            | 99+              |

### K12 – The count adds up both lists
Source: issue #1002; user decision 2026-11-19 (household plus private); user decision 2026-11-20 (ticked items not counted, "99+").
| Situation                                     | Number on Einkauf |
| --------------------------------------------- | ----------------- |
| no household, private list 7 open             | 7                 |
| household list 3 open, private list 4 open    | 7                 |
| household list 3 open, private list 0 open    | 3                 |
| household list 0 open, private list 1 open    | 1                 |
| private list 5 items, 2 of them ticked off    | 3                 |
| household list 60 open, private list 40 open  | 99+               |
| household list 2 ticked off, private list 0   | no number         |

### K13 – Tool names in the headers in normal case
Source: issue #1002 ("Die Namen unter den Werkzeugen … in normaler Schreibung"); user decision 2026-11-19 ("Normal, wie unten").
Given: I am in Vorrat or Kochbuch.
When: I look at the names under the header tools.
Then: each tool keeps its word as today, written in normal case, e.g. "Verlauf", "Einkauf", "Neu", not "VERLAUF", "EINKAUF", "NEU".
Only the case changes, not the words. The tool word "Geräte" in mock Schnell-D-Tabs.dc.html and in the issue's list does not apply.

### K14 – Einkauf carries its word in every header
Source: user decision 2026-11-20 (icon plus word, correcting "nur Icon" the same day); mock Schnell-D-Tabs.dc.html. Mock Schnell-D.dc.html shows the diary icon without the word; that does not apply.
Given: Einkauf shows in the header of Tagebuch, Vorrat or Kochbuch.
When: I look at it.
Then: the shopping icon shows with the word "Einkauf" under it.
