# YAMT

**Yet Another Meal Tracker** ist eine Flutter-App, deren Hauptfunktion ein
intelligentes Ernährungstagebuch zum Kalorienzählen ist. Open Food Facts dient
als wichtigste Produktdatenquelle. Ergänzt wird das Tagebuch durch einen
gemeinsamen Vorrat, Kassenzettelerkennung, Rezeptplanung und eine
haushaltsweite Echtzeitsynchronisierung.

YAMT betrachtet Lebensmittel nicht als voneinander getrennte Einträge. Ein
Produkt kann über einen Kassenzettel in den Vorrat gelangen, später in einem
Rezept verwendet und schließlich direkt als gegessen im Tagebuch eingetragen
werden. Android und iOS sind die primären Zielplattformen.

## Technische Highlights

- **Adaptives Kalorienmodell:** Der persönliche Gesamtenergiebedarf wird aus
  Ernährungstagebuch und Gewichtsverlauf abgeleitet. Die Berechnung liegt in
  der [Kalorienlogik](lib/features/calories/) und ist durch
  [Provider-Tests](test/features/calories/) abgedeckt.
- **Wochenbudget statt starrer Tagesgrenze:** Überschüsse, Defizite und
  Aktivitätsgutschriften werden über eine ganze Woche verteilt. Die
  Burn-Week-Logik bleibt getrennt von der Darstellung und ist gezielt
  getestet.
- **Fehlertolerante Abläufe zwischen Features:** Einträge aus dem Vorrat
  werden konsistent ins Tagebuch übernommen und können nachvollziehbar
  rückgängig gemacht werden. Dafür existieren ein eigener Speicherablauf in
  der [Vorratslogik](lib/features/inventory/) und Regressionstests.
- **Qualitätsbewusste Produktsuche:** Suchtreffer werden anhand ihrer
  Nährwertdaten bewertet, statt unvollständige Produkte stillschweigend zu
  übernehmen. Bewertung und [Tests](test/features/inventory/) liegen im
  jeweiligen Feature.
- **Abgesicherte Echtzeitdaten:** Versionierte
  [Firestore-Regeln](firestore.rules) schützen Benutzer- und Haushaltsdaten.
  Kritische Freigaben werden zusätzlich in
  [Rules-Tests](test/firestore_serving_suggestion_rules_test.dart) geprüft.

## Kernidee

### Ernährungstagebuch mit schneller Produkterfassung

Lebensmittel lassen sich auf mehreren Wegen erfassen:

- Barcode-Scan mit Produktdaten von Open Food Facts
- manuelle Suche mit schnellem Autocomplete über Meilisearch
- manuelle Eingabe eigener Lebensmittel
- KI-gestützter Nährwertvorschlag aus einer kurzen Beschreibung
- Foto einer Nährwerttabelle zur automatischen Erkennung fehlender Werte
- zuletzt verwendete Produkte für wiederkehrende Einträge

Unvollständige Suchergebnisse werden nicht ausgeblendet. YAMT bewertet die
Qualität vorhandener Nährwerte und öffnet bei Bedarf einen Editor, in dem
fehlende Angaben per OCR oder manuell ergänzt werden können.

Parallel zu Open Food Facts entsteht ein eigener globaler Produktkatalog. Er
speichert bestätigte Produkte, Korrekturen, Aliase und Portionsvorschläge. Der
self-hosted Suchdienst hält außerdem einen importierten Open-Food-Facts-Dump in
MongoDB vor. Damit besitzt YAMT eine ergänzende Datenbasis und ist bei Suche und
Produktauflösung nicht ausschließlich von der öffentlichen API abhängig.

### Dynamisches Kalorienbudget für die ganze Woche

Ein Tagesziel ist selten jeden Tag gleich gut einzuhalten. Deshalb verteilt
YAMT Kalorien dynamisch über eine Woche. Wer an einem Tag mehr oder weniger
isst, sieht sofort, wie sich das verbleibende Wochenbudget verändert.

Die Burn-Week-Übersicht kombiniert:

- tägliches Kalorienziel
- verbleibendes Wochenbudget
- Übertrag zwischen einzelnen Tagen
- kontrollierte Gutschrift zusätzlicher Aktivität
- ausgelassene Tage und nachträgliche Einträge
- Makronährstoffe für Protein, Kohlenhydrate und Fett

Dadurch kann ein höherer Verbrauch oder ein gemeinsames Essen an einem Tag im
weiteren Wochenverlauf ausgeglichen werden, ohne nur auf eine isolierte
Tageszahl zu schauen.

### Lernender tatsächlicher Kalorienbedarf

YAMT verwendet nicht dauerhaft nur einen statisch berechneten Grundumsatz. Ein
Startwert entsteht aus Körperdaten, Aktivitätsprofil und Gewichtsziel. Danach
wird der tatsächliche Gesamtenergiebedarf, also der TDEE, wöchentlich anhand
der aufgezeichneten Energieaufnahme und des Gewichtsverlaufs neu bewertet.

Nach der ersten vollständigen Woche kann die Schätzung erstmals angepasst
werden. Nach ungefähr zwei Wochen konsequentem Tracking entsteht ein deutlich
belastbareres Bild des persönlichen Bedarfs. Wöchentliche Check-ins zeigen auch
an, wenn für eine sinnvolle Berechnung noch Gewichts- oder Ernährungstage
fehlen.

### Gesundheit und Aktivität

Health Connect und Apple Health können Schritte, Workouts, verbrannte Kalorien
und Körpergewicht bereitstellen. Zusätzliche Aktivität fließt kontrolliert in
das Kalorienbudget ein, weil aufgezeichnete Aktivitätskalorien immer nur
Schätzwerte sind. Gewicht kann alternativ vollständig manuell gepflegt werden.

## Erweiterte Funktionen

### Vorrat und Kassenzettel

Kassenzettel können per Kamera, Galerie, PDF oder Teilen-Funktion importiert
werden. Firebase AI erkennt Positionen, Preise, Mengen, Geschäft und Datum.
Die erkannten Artikel werden mit vorhandenen Produkt- und Barcodedaten
abgeglichen und vor dem Speichern einzeln überprüft.

Im Vorrat bleiben Menge, Einheit, Preis, Kaufdatum und Kassenzettelbezug
erhalten. Lebensmittel können direkt als gegessen, aufgebraucht oder
weggeworfen markiert werden. Dieselben Wege wie im Tagebuch stehen auch beim
Hinzufügen zum Vorrat zur Verfügung: Barcode, Suche, KI oder manuelle Eingabe.

So wird sichtbar, was zu Hause vorhanden ist, was bald aufgebraucht werden
sollte und welche Zutaten sich gemeinsam verkochen lassen.

### Haushalte und Echtzeitsynchronisierung

Mitglieder treten über Einladungscodes einem Haushalt bei. Firestore
synchronisiert Vorrat, Einkaufsliste, Küchenutensilien, vorbereitete Mahlzeiten
und zugehörige Änderungen in Echtzeit. Persönliche Kalorien- und Gesundheits-
daten bleiben weiterhin dem jeweiligen Konto zugeordnet.

### Rezepte, Mahlzeiten und Kochablauf

Ein Rezeptparser importiert Rezepte von Webseiten, derzeit insbesondere von
Chefkoch. Zutaten werden normalisiert, an den Vorrat angeglichen und auf die
gewünschte Portionszahl skaliert. Fehlende Zutaten können direkt auf die
Einkaufsliste gesetzt werden.

Der Kochablauf führt durch Vorratsprüfung, Zutatenzuordnung, Vorbereitung,
Kochen, spontane Anpassungen, Behältergewicht und Portionierung. Gespeicherte
Küchenutensilien liefern bekannte Taragewichte. Fertige Gerichte werden als
vorbereitete Mahlzeit zurück in den Vorrat geschrieben und lassen sich später
portionsweise essen, verwerfen oder als Vorlage wiederverwenden.

### Einkaufsliste

Die grundlegende Einkaufsliste unterstützt Mengen, geschätzte Summen,
Abhaken und Einträge aus Vorrat, Rezepten und Kochablauf.

## Weitere umgesetzte Funktionen

- Gastkonto sowie Anmeldung mit E-Mail, Passwort oder Google
- Verknüpfung eines Gastkontos mit einem dauerhaften Konto
- Onboarding für Abnehmen, Gewicht halten oder Zunehmen
- vorbereitete Mahlzeiten mit Preis-, Gewichts- und Nährwertberechnung
- deutsch- und englischsprachige Oberfläche
- helle, dunkle und systemabhängige Darstellung mit wählbarer Grundfarbe
- erste Version eines inventarbasierten KI-Kochassistenten mit bearbeitbaren
  Rezeptvorschlägen
- klare Qualitätsstufen für geschätzte, unvollständige und bestätigte
  Nährwertdaten
- nachvollziehbare Korrektur- und Wiederherstellungsabläufe zwischen Vorrat
  und Tagebuch

Eine ausführlichere Funktionsübersicht steht in [features.md](features.md).
Featuregrenzen und öffentliche Schnittstellen sind direkt neben dem Code in
`lib/features/*/README.md` dokumentiert.

## Roadmap

- **Mahlzeitenplaner:** Vorgekochte Portionen einer Woche und einzelnen
  Mahlzeiten zuordnen und anschließend besonders schnell eintragen.
- **Smarte Einkaufsplanung:** Häufig gekaufte oder bald aufgebrauchte
  Lebensmittel automatisch für den nächsten Einkauf vorschlagen.
- **KI-Kochassistent:** Zutatenabgleich, Zuverlässigkeit und Nutzerführung der
  vorhandenen ersten Version weiter ausbauen.
- **Statistiken:** Ausgaben, Preisentwicklung und Lebensmittelverschwendung
  nach Woche, Monat und Jahr auswerten. Geplant sind außerdem Ranglisten für
  günstige Protein-, Kohlenhydrat- und andere Nährstoffquellen auf Basis
  tatsächlich gekaufter Produkte.

## Architektur

YAMT verwendet eine Feature-First-Architektur mit pragmatischen
Clean-Architecture-Schichten und Riverpod-gesteuertem MVVM. Zustandsverwaltende
Klassen tragen den Suffix `Controller`.

```text
lib/
├── core/                    # globale Infrastruktur und UI-Grundbausteine
└── features/
    └── <feature>/
        ├── data/            # Repositorys und externe Clients
        ├── domain/          # Modelle und reine Geschäftsregeln
        ├── application/     # Abläufe und Datenaggregation
        └── presentation/    # Seiten, Widgets und Riverpod-Controller
```

Provider liegen direkt bei ihrer Implementierung. Abhängigkeiten zwischen
Features laufen über dokumentierte öffentliche Schnittstellen. `core` bleibt
von konkreten Produktfeatures unabhängig. Weitere Regeln stehen in
[architecture.md](architecture.md).

## Technologie-Stack

### Flutter-Client

- Flutter und Dart 3 mit Sound Null Safety
- Riverpod 3 mit `@riverpod`-Codegenerierung für Zustand und Dependency
  Injection
- `go_router` mit zustandsbehafteter Tab-Navigation und Weiterleitungen
- Freezed, `json_serializable` und `json_annotation` für unveränderliche Modelle
- zentralisiertes `ThemeData` auf Basis von `ColorScheme.fromSeed`
- generierte deutsche und englische Lokalisierung über `AppLocalizations`

### Firebase-Backend

- Firebase Authentication für Gast-, E-Mail- und Google-Konten
- Cloud Firestore für Benutzer-, Haushalts-, Vorrats-, Tagebuch- und
  Katalogdaten
- Cloud Storage für generierte Rezeptbilder und Fotos von Küchenutensilien
- Firebase AI Logic mit Vertex AI für Kassenzettel, Nährwert-OCR,
  Produktvorschläge, Rezepte und Bildgenerierung
- Firebase App Check und versionierte Firebase-Sicherheitsregeln
- Firebase Emulator Suite für lokale Auth- und Firestore-Entwicklung

### Open-Food-Facts-Suchdienst

Der Flutter-Client verwendet `https://api.yamt.de/search` für schnelle Text-
und Barcode-Suchen. Der bewusst kleine, selbst betriebene Dienst liegt
außerhalb dieses Repositories und besteht aus:

- Open-Food-Facts-Produktdumps als Datenquelle
- MongoDB für den importierten Quelldatensatz
- Mongo Express für lokale Datenprüfung und Prototyping
- Meilisearch als aktivem Index für fehlertolerante Suche und Ranking
- einer Python-API auf Basis von `ThreadingHTTPServer` mit `/search` und
  `/barcode`
- systemd für den dauerhaften API-Prozess
- Caddy für HTTPS und Reverse Proxying
- Docker Compose für MongoDB, Meilisearch und optionale Suchdienste
- Bash-, Python- und JavaScript-Skripten für Import, Normalisierung,
  Anreicherung und Indexaufbau

Elasticsearch steht für Vergleichstests bereit, ist aber nicht Teil des
aktiven Produkt-Suchpfads. Dieser verwendet derzeit Meilisearch und MongoDB.
Endpunkt und Timeout lassen sich beim Build über `OFF_PRODUCT_SEARCH_URL` und
`OFF_PRODUCT_SEARCH_TIMEOUT_SECONDS` ändern.

### Geräte- und externe Integrationen

- Health Connect und Apple Health
- Kamera, Galerie, Dateiauswahl, PDF und systemweite Teilen-Funktion
- mobiler Barcode-Scan und Spracheingabe für die Suche
- Chefkoch- und Online-Rezeptimport via Schema.org / JSON-LD
- Produktbilder von Open Food Facts

## Tests

Das Repository enthält mehr als 400 Unit-, Provider-, Repository-, Widget-,
Golden-, Routing- und Firebase-Rules-Testdateien sowie native
Integrationstests. Tests verwenden bevorzugt Fakes und Stubs. Firebase-Abläufe
werden nach Möglichkeit mit lokalen Fakes oder der Emulator Suite geprüft.

```bash
flutter test
flutter analyze
```

Android-Integrationstests verwenden einen sauberen, headless gestarteten
Emulator-Snapshot:

```bash
./tool/android_integration_emulator.sh prepare-snapshot
./tool/android_integration_emulator.sh run
```

## Lokale Entwicklung

Vorausgesetzt werden Flutter Stable, eine Android- oder iOS-Toolchain und die
Firebase CLI für lokale Backend-Emulatoren.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Änderungen an Riverpod-, Freezed- oder JSON-Modellen erfordern einen erneuten
`build_runner`-Lauf. Firebase-Konfiguration und Sicherheitsregeln liegen im
Wurzelverzeichnis des Repositories.

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
