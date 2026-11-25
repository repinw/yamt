# yamt-Logo: Einbauorte

Abgenommen vom User am 25.11.2026: seine Handskizze "YAMT" als Wortmarke; als Icon die ganze Schrift, fein wie gezeichnet, auf Karopapier mit limettenfarbenem Rahmen (#B6F23A, 5 dp).
Alle Dateien liegen in diesem Ordner. Eingebaut sind App-Icon und Startbild für Android und iOS; offen sind Play Store, Website und die dunklen iOS-Fassungen.

Farben: Tinte #15161A, Papier #E4E9F0, Karolinien #A7B2C1. Dunkel: Papier #1B1D22, Linien #3A404C, Tinte #F4F6F9.

## Android (`android/app/src/main/res/`)
Eingebaut:
- `android/mipmap-*/ic_launcher.png` ersetzt die fünf vorhandenen Dateien.
- Neu: `android/mipmap-anydpi-v26/ic_launcher.xml` und je Dichte `ic_launcher_foreground.png`, `ic_launcher_background.png`, `ic_launcher_monochrome.png`.
- `AndroidManifest.xml` Zeile 30 (`android:icon="@mipmap/ic_launcher"`) bleibt gleich.
- Nicht betroffen: `drawable/ic_notification.xml` (eigene Glocke für Benachrichtigungen) und die Widget-Icons.
- Startbild: `android/drawable-*/launch_logo.png` (dunkle Tinte) und `android/drawable-night-*/launch_logo.png` (helle Tinte); `drawable/launch_background.xml` und `drawable-v21/launch_background.xml` zeigen `@drawable/launch_logo` mittig.

## iOS (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- Die 15 Dateien in `ios/AppIcon.appiconset/` haben dieselben Namen wie im Projekt und ersetzen sie; `Contents.json` bleibt.
- `ios/extra/` enthält die dunkle und die getönte Fassung (1024 px). Dafür braucht `Contents.json` neue Einträge (`appearances` dark und tinted).
- Startbild: `ios/LaunchImage.imageset/` (220x157 pt, 1x bis 3x) ersetzt die drei Dateien in `ios/Runner/Assets.xcassets/LaunchImage.imageset/`; `LaunchScreen.storyboard` nennt die Größe 220x157.

## Play Store
- `play/play-icon-512.png` in der Play Console hochladen (512 px, ohne Transparenz).

## Website (`~/dev/yamt-landing`, eigene Sitzung "website")
- `web/favicon-32.png`, `web/apple-touch-icon.png`, `web/icon-192.png`, `web/icon-512.png`.
- Wortmarke: `svg/yamt-wortmarke.svg` (nur Tinte) oder `svg/yamt-wortmarke-karo.svg` (auf Karopapier).

## In der App
- Die App zeigt heute nirgends ein Logo-Bild (kein Logo-Asset in `pubspec.yaml`). Wer es zeigen will (Onboarding, Über-Seite): `svg/yamt-wortmarke.svg` als Asset aufnehmen; auf dunklem Grund die Füllfarbe auf #F4F6F9 setzen.

## Hinweise
- Die Striche der ganzen Schrift sind im Icon bei 48 px nur etwa 1 px breit, und die Schraffur im A läuft klein zu Grau zu. Der User hat diese feine Fassung bewusst gewählt. Die kräftigere liegt als `../varianten/yamt-icon-wort.svg` bereit.
- Neu bauen (mit Rahmen, so wie eingebaut): `python3 ../tools/export_final.py ../varianten . yamt-icon-wort-wie-gezeichnet-r29.svg 5`. Ohne die letzten zwei Angaben entsteht das Icon ohne Rahmen. Das Skript baut auch die Startbilder; danach die Dateien aus `android/` und `ios/` in die App-Ordner kopieren.
