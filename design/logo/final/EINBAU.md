# yamt-Logo: Einbauorte

Abgenommen vom User am 25.11.2026: seine Handskizze "YAMT" als Wortmarke; als Icon die ganze Schrift, fein wie gezeichnet, auf Karopapier.
Alle Dateien liegen in diesem Ordner. In der App selbst ist noch nichts eingebaut.

Farben: Tinte #15161A, Papier #E4E9F0, Karolinien #A7B2C1. Dunkel: Papier #1B1D22, Linien #3A404C, Tinte #F4F6F9.

## Android (`android/app/src/main/res/`)
Heute gibt es nur `mipmap-*/ic_launcher.png` (48 bis 192 px), kein adaptives Icon.
- `android/mipmap-*/ic_launcher.png` ersetzt die fünf vorhandenen Dateien.
- Neu: `android/mipmap-anydpi-v26/ic_launcher.xml` und je Dichte `ic_launcher_foreground.png`, `ic_launcher_background.png`, `ic_launcher_monochrome.png`.
- `AndroidManifest.xml` Zeile 30 (`android:icon="@mipmap/ic_launcher"`) bleibt gleich.
- Nicht betroffen: `drawable/ic_notification.xml` (eigene Glocke für Benachrichtigungen) und die Widget-Icons.
- Startbild `drawable/launch_background.xml` ist heute weiß und ohne Logo. Offen: Wortmarke dort zeigen (wäre eine eigene Entscheidung).

## iOS (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- Die 15 Dateien in `ios/AppIcon.appiconset/` haben dieselben Namen wie im Projekt und ersetzen sie; `Contents.json` bleibt.
- `ios/extra/` enthält die dunkle und die getönte Fassung (1024 px). Dafür braucht `Contents.json` neue Einträge (`appearances` dark und tinted).
- `LaunchImage.imageset` ist heute leer; wie beim Android-Startbild offen.

## Play Store
- `play/play-icon-512.png` in der Play Console hochladen (512 px, ohne Transparenz).

## Website (`~/dev/yamt-landing`, eigene Sitzung "website")
- `web/favicon-32.png`, `web/apple-touch-icon.png`, `web/icon-192.png`, `web/icon-512.png`.
- Wortmarke: `svg/yamt-wortmarke.svg` (nur Tinte) oder `svg/yamt-wortmarke-karo.svg` (auf Karopapier).

## In der App
- Die App zeigt heute nirgends ein Logo-Bild (kein Logo-Asset in `pubspec.yaml`). Wer es zeigen will (Onboarding, Über-Seite): `svg/yamt-wortmarke.svg` als Asset aufnehmen; auf dunklem Grund die Füllfarbe auf #F4F6F9 setzen.

## Hinweise
- Die Striche der ganzen Schrift sind im Icon bei 48 px nur etwa 1 px breit, und die Schraffur im A läuft klein zu Grau zu. Der User hat diese feine Fassung bewusst gewählt. Die kräftigere liegt als `../varianten/yamt-icon-wort.svg` bereit.
- Neu bauen: `python3 ../tools/export_final.py ../varianten .`
