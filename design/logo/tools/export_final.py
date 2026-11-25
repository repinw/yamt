#!/usr/bin/env python3
"""Abgenommenes Logo: alle Exporte bauen. Aufruf: export_final.py <r6-ordner> <ziel-ordner>"""
import os, re, subprocess, sys
src, out = sys.argv[1], sys.argv[2]
s = open(f'{src}/yamt-icon-wort-wie-gezeichnet.svg').read()
bg = re.search(r'(<rect width="108" height="108" fill="#E4E9F0"/><g stroke="#A7B2C1".*?</g>)', s).group(1)
fg = re.search(r'(<g transform="translate.*?</g>)', s).group(1)
def svg(body, vb='0 0 108 108'):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}"><defs><clipPath id="c"><rect width="108" height="108"/></clipPath></defs><g clip-path="url(#c)">{body}</g></svg>\n'
dark = lambda t: t.replace('#E4E9F0', '#1B1D22').replace('#A7B2C1', '#3A404C').replace('#15161A', '#F4F6F9')
mono = fg.replace('#15161A', '#000000')
files = {
 'svg/yamt-icon.svg': svg(bg + fg),
 'svg/yamt-icon-vordergrund.svg': svg(fg),
 'svg/yamt-icon-hintergrund.svg': svg(bg),
 'svg/yamt-icon-einfarbig.svg': svg(mono),
 'svg/yamt-icon-quadrat.svg': svg(bg + fg, '18 18 72 72'),
 'svg/yamt-icon-quadrat-dunkel.svg': svg(dark(bg + fg), '18 18 72 72'),
 'svg/yamt-icon-quadrat-getoent.svg': svg('<rect width="108" height="108" fill="#000"/>' + fg.replace('#15161A', '#FFFFFF'), '18 18 72 72'),
}
for d in ('svg', 'android', 'ios', 'web', 'play'):
    os.makedirs(f'{out}/{d}', exist_ok=True)
for name, text in files.items():
    open(f'{out}/{name}', 'w').write(text)
for n in ('yamt-wortmarke.svg', 'yamt-wortmarke-karo.svg'):
    open(f'{out}/svg/{n}', 'w').write(open(f'{src}/{n}').read())
def png(name, w, dst, flat=None):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    cmd = ['rsvg-convert', '-w', str(w), '-h', str(w), f'{out}/svg/{name}', '-o', dst]
    subprocess.run(cmd, check=True)
    if flat:
        subprocess.run(['magick', dst, '-background', flat, '-alpha', 'remove', '-alpha', 'off', dst], check=True)
# Android: adaptive Ebenen (108 dp) und alte Icons (48 dp) je Dichte
open(f'{out}/android/mipmap-anydpi-v26/ic_launcher.xml', 'w') if os.makedirs(f'{out}/android/mipmap-anydpi-v26', exist_ok=True) else None
open(f'{out}/android/mipmap-anydpi-v26/ic_launcher.xml', 'w').write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@mipmap/ic_launcher_background" />\n    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n</adaptive-icon>\n')
for dens, k in (('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)):
    d = f'{out}/android/mipmap-{dens}'
    png('yamt-icon-vordergrund.svg', int(108 * k), f'{d}/ic_launcher_foreground.png')
    png('yamt-icon-hintergrund.svg', int(108 * k), f'{d}/ic_launcher_background.png', '#E4E9F0')
    png('yamt-icon-einfarbig.svg', int(108 * k), f'{d}/ic_launcher_monochrome.png')
    png('yamt-icon-quadrat.svg', int(48 * k), f'{d}/ic_launcher.png', '#E4E9F0')
png('yamt-icon-quadrat.svg', 512, f'{out}/play/play-icon-512.png', '#E4E9F0')
# iOS: dieselben Dateinamen wie im Projekt, ohne Transparenz
for base, scales in ((20, (1, 2, 3)), (29, (1, 2, 3)), (40, (1, 2, 3)), (60, (2, 3)), (76, (1, 2)), (83.5, (2,)), (1024, (1,))):
    for sc in scales:
        b = str(base).rstrip('0').rstrip('.') if isinstance(base, float) else str(base)
        png('yamt-icon-quadrat.svg', int(round(base * sc)), f'{out}/ios/AppIcon.appiconset/Icon-App-{b}x{b}@{sc}x.png', '#E4E9F0')
png('yamt-icon-quadrat-dunkel.svg', 1024, f'{out}/ios/extra/Icon-App-1024-dunkel.png', '#1B1D22')
png('yamt-icon-quadrat-getoent.svg', 1024, f'{out}/ios/extra/Icon-App-1024-getoent.png', '#000000')
for w, n in ((32, 'favicon-32.png'), (180, 'apple-touch-icon.png'), (192, 'icon-192.png'), (512, 'icon-512.png')):
    png('yamt-icon-quadrat.svg', w, f'{out}/web/{n}', '#E4E9F0')
print('fertig')
