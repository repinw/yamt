#!/usr/bin/env python3
"""Runde 6: Icon mit der ganzen Wortmarke auf Karopapier. Aufruf: icon_wort.py <yamt-wortmarke.svg> <masse.json> <aus-ordner> [fett=4] [radius=32]"""
import json, math, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import r6lib as L
src, mj, out = sys.argv[1:4]
fat = float(sys.argv[4]) if len(sys.argv) > 4 else 4.0
RAD = float(sys.argv[5]) if len(sys.argv) > 5 else 32.0
d = re.search(r' d="([^"]*)"', open(src).read()).group(1)
bx0, by0, bx1, by1 = json.load(open(mj))['ink_bbox']
nums = [float(v) for v in re.findall(r'-?\d+\.\d+', d)]
pts = [(nums[i] + bx0 - 16, nums[i + 1] + by0 - 16) for i in range(0, len(nums), 2)]  # Foto-Pixel
cx = sum(p[0] for p in pts) / len(pts); cy = sum(p[1] for p in pts) / len(pts)
for it in range(6000):
    far = max(pts, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    k = 0.01 / (1 + it * 0.01); cx += (far[0] - cx) * k; cy += (far[1] - cy) * k
R = max(math.hypot(p[0] - cx, p[1] - cy) for p in pts) + fat / 2
s = RAD / R
tx, ty = 54 - (cx - bx0 + 16) * s, 54 - (cy - by0 + 16) * s
fi = lambda p: ((p[0] - cx) * s + 54, (p[1] - cy) * s + 54)
gx0, gy0, gx1, gy1 = cx - 54 / s, cy - 54 / s, cx + 54 / s, cy + 54 / s
lines = ''.join(f'<line x1="{fi(a)[0]:.2f}" y1="{fi(a)[1]:.2f}" x2="{fi(b)[0]:.2f}" y2="{fi(b)[1]:.2f}"/>' for a, b in L.grid_lines(gx0, gy0, gx1, gy1))
body = (f'<rect width="108" height="108" fill="#E4E9F0"/><g stroke="#A7B2C1" stroke-width="{L.GRID_WIDTH * s:.2f}">{lines}</g>'
        f'<g transform="translate({tx:.3f} {ty:.3f}) scale({s:.5f})"><path fill="#15161A" stroke="#15161A" stroke-width="{fat}" stroke-linejoin="round" fill-rule="evenodd" d="{d}"/></g>')
open(f'{out}/yamt-icon-wort.svg', 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs><clipPath id="c"><rect width="108" height="108"/></clipPath></defs><g clip-path="url(#c)">{body}</g></svg>\n')
open(f'{out}/_icon_wort_sq.svg', 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="18 18 72 72"><defs><clipPath id="q"><path d="{L.squircle(54, 54, 36)}"/></clipPath></defs><g clip-path="url(#q)">{body}</g></svg>\n')
print(f'Maßstab {s:.4f}, Strich etwa {(11 + fat) * s:.2f} dp')
