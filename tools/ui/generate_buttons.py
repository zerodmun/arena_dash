"""Generate the shared rounded button artwork. No filters or runtime shaders.
64px high, 30px radius; nine-slice corners retain a capsule silhouette.
"""
from pathlib import Path
OUT = Path(__file__).resolve().parents[2] / 'assets/ui/theme/buttons'
OUT.mkdir(parents=True, exist_ok=True)
PALETTES = {
    'secondary': ('#5b7c8f', '#466274', '#3b5369', '#9db8c6'),
    'primary': ('#dec19b', '#cca574', '#b98d5b', '#ead3b0'),
    'selected': ('#4d858b', '#36656e', '#2c505e', '#a5d1d0'),
}
def rgb(value): return tuple(int(value[i:i+2],16) for i in (1,3,5))
def shade(value, factor):
    return '#' + ''.join(f'{max(0,min(255,round(v*factor))):02x}' for v in rgb(value))
def frame(name, top, mid, bottom, border, pressed=False, disabled=False):
    highlight = '.045' if disabled else '.09' if pressed else '.17'
    # Identical extents/radii for every state. All shading stays inside the silhouette.
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="64" viewBox="0 0 256 64">
<defs>
 <linearGradient id="face" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
  <stop offset="0" stop-color="{top}"/><stop offset=".48" stop-color="{mid}"/><stop offset="1" stop-color="{bottom}"/>
 </linearGradient>
 <linearGradient id="edge" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
  <stop offset="0" stop-color="{border}"/><stop offset="1" stop-color="{shade(border,.64)}"/>
 </linearGradient>
 <clipPath id="rounded"><rect x="2" y="2" width="252" height="60" rx="30"/></clipPath>
</defs>
<rect x="2" y="2" width="252" height="60" rx="30" fill="url(#face)" stroke="url(#edge)" stroke-width="2"/>
<g clip-path="url(#rounded)">
 <rect x="4" y="4" width="248" height="56" rx="28" fill="none" stroke="#d8e6f0" stroke-opacity="{highlight}" stroke-width="1"/>
 <path d="M 14 47 Q 23 59 34 59 H 222 Q 233 59 242 47" fill="none" stroke="#060e1c" stroke-opacity="{'.18' if pressed else '.32'}" stroke-width="2" stroke-linecap="round"/>
</g>
</svg>'''
    (OUT / f'{name}.svg').write_text(svg)
for kind, colors in PALETTES.items():
    frame(kind+'_normal', *colors)
    frame(kind+'_hover', *(shade(c,1.08) for c in colors))
    frame(kind+'_pressed', shade(colors[0],.76),shade(colors[1],.84),shade(colors[2],.96),colors[3],pressed=True)
frame('disabled','#344257','#2b384b','#253246','#5b6a80',disabled=True)
(OUT/'focus.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="64" viewBox="0 0 256 64">
<rect x="2" y="2" width="252" height="60" rx="30" fill="none" stroke="#a4c3d2" stroke-opacity=".8" stroke-width="2"/>
<rect x="5" y="5" width="246" height="54" rx="27" fill="none" stroke="#a4c3d2" stroke-opacity=".18" stroke-width="1"/>
</svg>''')
# Reuse the existing circular crosshair design in the same muted material system.
for state, colors in {'normal':PALETTES['primary'], 'pressed':tuple(shade(c,.84) for c in PALETTES['primary']), 'disabled':('#344257','#2b384b','#253246','#5b6a80')}.items():
    top,mid,bottom,border=colors
    glyph = "#8c9ba9" if state=="disabled" else "#182535"
    (OUT/f'fire_{state}.svg').write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<defs><linearGradient id="f" x2="0" y2="1"><stop stop-color="{top}"/><stop offset=".5" stop-color="{mid}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>
<circle cx="128" cy="128" r="119" fill="url(#f)" stroke="{border}" stroke-width="2"/>
<circle cx="128" cy="128" r="115" fill="none" stroke="#c9deeb" stroke-opacity=".12"/>
<path d="M 39 198 A 113 113 0 0 0 217 198" fill="none" stroke="#0d192a" stroke-opacity=".45" stroke-width="3" stroke-linecap="round"/>
<circle cx="128" cy="128" r="62" fill="none" stroke="{glyph}" stroke-width="3"/>
<path d="M128 50 V82 M128 174 V206 M50 128 H82 M174 128 H206" fill="none" stroke="{glyph}" stroke-width="3" stroke-linecap="round"/>
<circle cx="128" cy="128" r="13" fill="{glyph}"/><circle cx="128" cy="128" r="6" fill="{mid}"/>
</svg>''')
# Retain the joystick's original geometry, grip rings and proportions; mute its
# bright blue/chrome colors so both gameplay controls share the button palette.
import re
colors = {'#0284c7':'#486278', '#0369a1':'#334c62', '#082f49':'#1b2b40',
          '#0ea5e9':'#7598ad', '#38bdf8':'#90b4c4', '#bae6fd':'#b7ced9',
          '#ffffff':'#bdcedb', '#e2e8f0':'#a4b8ca', '#94a3b8':'#7b91a7'}
for part in ('base','knob'):
    source = OUT.parents[1] / 'controls' / f'control_joystick_{part}.svg'
    art = source.read_text()
    art = re.sub(r'<filter\b.*?</filter>', '', art, flags=re.S)
    art = re.sub(r' filter="[^"]*"', '', art)
    for old,new in colors.items(): art = art.replace(old,new)
    (OUT / f'joystick_{part}.svg').write_text(art)

print('Generated',len(list(OUT.glob('*.svg'))),'rounded button/control assets')
