# Kochmodus – acceptance criteria

Criteria for the cooking mode. This file covers only the parts listed below;
the rest of Kochmodus has no criteria yet.

Source "built rule" means: the behavior on master fd983367e, taken over as a
criterion by the caller on 2026-11-18 (no mock or user decision behind it yet).

## Zutaten unter einem Schritt

User decision 2026-11-18 ("Erstmal raus"): the app does not match a step's
text to the recipe lines at all. Any later automatic assignment runs
machine-based without fixed word lists (issue #994). K1–K8 are retired; K9
replaces them.

### K1 – A step shows the lines it names
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K2 – The step names the food by the whole word, in either number
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K3 – A step word that ends the food's compound names it
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K4 – Short and long name of the same food name each other
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K5 – A step word that starts a different food does not name it
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K6 – A food word inside a longer step word does not name it
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K7 – Words that are not the food never name it
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K8 – Lines set to ignore stay hidden, except the not-counted ones
Retired 2026-11-18: no ingredient lines under a step any more (user decision 2026-11-18, issue #994); see K9.

### K9 – A step shows its sentence and no recipe lines
Source: user decision 2026-11-18 ("Erstmal raus"); issue #994.
Given: a recipe with the lines "1 Zwiebel" and "2 Knoblauchzehen", and the
step "Zwiebel und Knoblauch im selben Topf andünsten".
When: I am on the tab "Kochen" at that step.
Then: the step shows its sentence, with its timers and "Noch zu wiegen" as
before.
And: no line of the recipe stands below the step, neither "1 Zwiebel" nor
"2 Knoblauchzehen", nor any other line; the cook reads the ingredient list.

## Erlaubnis für genaue Wecker beim Kochstart

Exact alarms exist only on Android; there, asking for them opens the system
screen "Alarms & reminders". The timer hint in a cooking step reads "Ohne
Erlaubnis für genaue Wecker kann der Timer ein paar Minuten später klingeln."
with the button "Erlauben".

"Declined" means: the cook came back from that system screen without
allowing exact alarms.

### W1 – Starting to cook asks for exact alarms
Source: user phone report 2026-11-18 ("Es gibt immer noch keine wecker
Berechtigungsabfrage beim start eines kochvorgangs"); PR #981 decision
2026-11-15 (permissions are asked at the start of cooking, not mid-step);
user decision 2026-11-18 ("Nach Ablehnen nie wieder").
Given: an Android phone where exact alarms are not allowed and the cook has
never declined them.
When: I start cooking a recipe.
Then: the system screen for exact alarms opens.
And: this happens at every start of cooking, as long as exact alarms are not
allowed and I have not declined.
And: it does not open in the middle of a step.
Phone only: that the real Android screen "Alarms & reminders" opens.

### W2 – After one decline the start never asks again
Source: user decision 2026-11-18 ("Nach Ablehnen nie wieder").
Given: at a start of cooking the exact alarm screen opened, and I came back
without allowing.
When: I start cooking again, also after the app was closed and opened again.
Then: the exact alarm screen does not open at the start.
And: the timer hint "Ohne Erlaubnis für genaue Wecker kann der Timer ein paar
Minuten später klingeln." with "Erlauben" still stands at the timer.

### W3 – Allowed exact alarms are not asked
Source: user decision 2026-11-18 (ask only while not allowed).
Given: exact alarms are allowed on the Android phone.
When: I start cooking.
Then: the exact alarm screen does not open.

### W4 – The exact alarm ask does not depend on the notification ask
Source: user phone report 2026-11-18; user decision 2026-11-18.
Given: an Android phone where the notification permission was already asked
earlier (allowed or denied, also by an older app version), exact alarms are
not allowed, and I have never declined them.
When: I start cooking.
Then: the exact alarm screen opens (W1).
And: denying notifications does not count as declining exact alarms.

### W5 – The notification permission is asked only once
Source: caller 2026-11-18 (the notification ask stays as built); PR #981
decision 2026-11-15 (asked at the start of cooking).
Given: the notification permission was asked once, at an earlier start of
cooking.
When: I start cooking again.
Then: the notification permission is not asked again.

### W6 – No exact alarm ask on iOS
Source: caller 2026-11-18 (exact alarms are always allowed on iOS).
Given: an iPhone.
When: I start cooking.
Then: nothing about exact alarms is asked.
