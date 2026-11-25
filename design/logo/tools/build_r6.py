#!/usr/bin/env python3
"""Runde 6: baut aus den Potrace-Spuren der Handskizze die SVG-Master (Wortmarke, Wortmarke auf Karopapier, Icon).

Aufruf: build_r6.py <arbeitsordner mit ink_k1.svg und ink_fein.svg> <ausgabeordner> [fett=7] [radius=28] [links=3]
fett = Verstärkung der Striche für das Icon in Foto-Pixeln (0 = wie gezeichnet).
radius = Radius des Y mit Schleife auf dem 108er-Raster (Schutzzone 33), links = Versatz nach links in dp.
"""
import json, math, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import r6lib as L

work, out = sys.argv[1], sys.argv[2]
fat = float(sys.argv[3]) if len(sys.argv) > 3 else 7.0
RAD = float(sys.argv[4]) if len(sys.argv) > 4 else 28.0
LEFT = float(sys.argv[5]) if len(sys.argv) > 5 else 3.0
os.makedirs(out, exist_ok=True)
INK, PAPER, LINE = '#15161A', '#E4E9F0', '#A7B2C1'

# 1. Ringe wählen: Umrisse aus der ruhigen Spur (k1), die Lücken der Schraffur aus der feinen Spur (d4).
k1 = [[r for r in rings if abs(L.info(r)[0]) > 4] for rings in L.parse(f'{work}/ink_k1.svg', 1)]
k1 = [rs for rs in k1 if rs and abs(L.info(rs[0])[0]) > 1000]
d4 = [rs for rs in L.parse(f'{work}/ink_fein.svg', 4) if rs and abs(L.info(rs[0])[0]) > 1000]

def pick(paths, x):
    """Die Figur, deren Umriss den Punkt mit diesem x-Rahmen enthält (T rechts, AM Mitte, Y links)."""
    return [rs for rs in paths if L.info(rs[0])[2][0] < x < L.info(rs[0])[2][2] and True][0]

def by_left(paths):
    return sorted(paths, key=lambda rs: L.info(rs[0])[2][0])

y_k1, am_k1, t_k1 = by_left(k1)
y_d4, am_d4, t_d4 = by_left(d4)
holes = lambda rs: sorted(rs[1:], key=lambda r: -abs(L.info(r)[0]))
T = [t_k1[0]]
AM = [am_k1[0], holes(am_k1)[0]] + [r for r in holes(am_d4)[1:] if abs(L.info(r)[0]) > 4]
Y = [y_k1[0], holes(y_k1)[0]]
WORD = Y + AM + T
print('Ringe: Y', len(Y), 'AM', len(AM), 'T', len(T))

def bbox(rings):
    bs = [L.info(r)[2] for r in rings]
    return min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs)

bx0, by0, bx1, by1 = bbox(WORD)
print('Tinte Rahmen', [round(v, 1) for v in (bx0, by0, bx1, by1)])

def svg_lines(lines, f, width, color):
    return ''.join(f'<line x1="{f(a)[0]:.2f}" y1="{f(a)[1]:.2f}" x2="{f(b)[0]:.2f}" y2="{f(b)[1]:.2f}"/>' for a, b in lines).join(
        (f'<g stroke="{color}" stroke-width="{width:.2f}" fill="none">', '</g>'))

# 2. Wortmarke, nur Tinte
m = 16
f1 = lambda p: (p[0] - bx0 + m, p[1] - by0 + m)
W1, H1 = bx1 - bx0 + 2 * m, by1 - by0 + 2 * m
open(f'{out}/yamt-wortmarke.svg', 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W1:.0f} {H1:.0f}" role="img" aria-label="yamt">'
    f'<path fill="{INK}" fill-rule="evenodd" d="{L.d_of(WORD, f1)}"/></svg>\n')

# 3. Wortmarke auf Karopapier
m2 = 56
px0, py0, px1, py1 = bx0 - m2, by0 - m2, bx1 + m2, by1 + m2
f2 = lambda p: (p[0] - px0, p[1] - py0)
W2, H2 = px1 - px0, py1 - py0
open(f'{out}/yamt-wortmarke-karo.svg', 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W2:.0f} {H2:.0f}" role="img" aria-label="yamt">'
    f'<defs><clipPath id="p"><rect width="{W2:.0f}" height="{H2:.0f}"/></clipPath></defs>'
    f'<rect width="{W2:.0f}" height="{H2:.0f}" fill="{PAPER}"/>'
    f'<g clip-path="url(#p)">{svg_lines(L.grid_lines(px0, py0, px1, py1), f2, L.GRID_WIDTH, LINE)}</g>'
    f'<path fill="{INK}" fill-rule="evenodd" d="{L.d_of(WORD, f2)}"/></svg>\n')

# 4. Icon: nur das Y mit Schleife; der Unterstrich läuft rechts aus dem Bild.
def fatten(rings, w):
    """Striche um w Foto-Pixel verstärken: mit Kontur rendern und neu nachzeichnen."""
    if w <= 0:
        return rings
    k = 4
    x0, y0, cw, ch = L.CROP
    src = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{cw * k}" height="{ch * k}" viewBox="{x0} {y0} {cw} {ch}">'
           f'<rect x="{x0}" y="{y0}" width="{cw}" height="{ch}" fill="#fff"/>'
           f'<path fill="#000" stroke="#000" stroke-width="{w}" stroke-linejoin="round" fill-rule="evenodd" d="{L.d_of(rings)}"/></svg>')
    open(f'{work}/_fat.svg', 'w').write(src)
    subprocess.run(['rsvg-convert', f'{work}/_fat.svg', '-o', f'{work}/_fat.png'], check=True)
    subprocess.run(['magick', f'{work}/_fat.png', '-alpha', 'off', '-colorspace', 'Gray', '-threshold', '50%', '-type', 'bilevel', f'{work}/_fat.pbm'], check=True)
    subprocess.run(['potrace', '-s', '--turdsize', '80', '--alphamax', '1.0', '--opttolerance', '0.8', f'{work}/_fat.pbm', '-o', f'{work}/_fat_tr.svg'], check=True)
    res = [rs for rs in L.parse(f'{work}/_fat_tr.svg', k) if rs and abs(L.info(rs[0])[0]) > 1000][0]
    return [res[0]] + sorted(res[1:], key=lambda r: -abs(L.info(r)[0]))[:1]

YI = fatten(Y, fat)
# kleinster Kreis um das Y mit Schleife (ohne den Unterstrich rechts vom Stamm)
pts = [p for r in YI for p in L.flat(r) if p[0] < 262]
cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
for it in range(4000):  # einfache Näherung des kleinsten Umkreises
    far = max(pts, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    step = 0.5 / (1 + it * 0.01)
    cx += (far[0] - cx) * step * 0.02; cy += (far[1] - cy) * step * 0.02
R = max(math.hypot(p[0] - cx, p[1] - cy) for p in pts)
s = RAD / R
print(f'Icon: Mitte ({cx:.1f},{cy:.1f}) Radius {R:.1f} Foto-Pixel, Maßstab {s:.4f} dp je Pixel')
fi = lambda p: ((p[0] - cx) * s + 54 - LEFT, (p[1] - cy) * s + 54)
inv = lambda q: ((q[0] - 54 + LEFT) / s + cx, (q[1] - 54) / s + cy)
gx0, gy0 = inv((0, 0)); gx1, gy1 = inv((108, 108))
icon_bg = (f'<rect width="108" height="108" fill="{PAPER}"/>'
           f'{svg_lines(L.grid_lines(gx0, gy0, gx1, gy1), fi, L.GRID_WIDTH * s, LINE)}')
icon_fg = f'<path fill="{INK}" fill-rule="evenodd" d="{L.d_of(YI, fi)}"/>'
open(f'{out}/yamt-icon.svg', 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" role="img" aria-label="yamt">'
    f'<defs><clipPath id="c"><rect width="108" height="108"/></clipPath></defs>'
    f'<g clip-path="url(#c)">{icon_bg}{icon_fg}</g></svg>\n')
json.dump({'cx': cx, 'cy': cy, 's': s, 'fat': fat, 'radius': RAD, 'links': LEFT, 'ink_bbox': [bx0, by0, bx1, by1]}, open(f'{out}/masse.json', 'w'))
# Vorschau des Icons als Squircle (sichtbarer Bereich 72 von 108)
open(f'{out}/_icon_sq.svg', 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="18 18 72 72">'
    f'<defs><clipPath id="q"><path d="{L.squircle(54, 54, 36)}"/></clipPath></defs>'
    f'<g clip-path="url(#q)">{icon_bg}{icon_fg}</g></svg>\n')
