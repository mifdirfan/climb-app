import json, sys
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding='utf-8')

all_nodes = {}
for fname in ['figma_nodes.json', 'figma_nodes_extra.json']:
    with open(fname, 'r', encoding='utf-8') as f:
        d = json.load(f)
        all_nodes.update(d.get('nodes', {}))

def to_hex(c):
    r = int(c.get('r', 0) * 255 + 0.5)
    g = int(c.get('g', 0) * 255 + 0.5)
    b = int(c.get('b', 0) * 255 + 0.5)
    return f'#{r:02X}{g:02X}{b:02X}'

colors = Counter()
strokes = Counter()
radii = Counter()
fonts = Counter()

def walk(node):
    for f in node.get('fills', []):
        if f.get('visible', True) and f.get('type') == 'SOLID' and 'color' in f:
            colors[to_hex(f['color'])] += 1
    for s in node.get('strokes', []):
        if s.get('visible', True) and s.get('type') == 'SOLID' and 'color' in s:
            strokes[to_hex(s['color'])] += 1
    if 'cornerRadius' in node:
        radii[node['cornerRadius']] += 1
    if node.get('type') == 'TEXT':
        st = node.get('style', {})
        fonts[(st.get('fontFamily'), st.get('fontSize'), st.get('fontWeight'))] += 1
    for c in node.get('children', []):
        walk(c)

for nid, n in all_nodes.items():
    walk(n.get('document', {}))

print("=== ALL COLORS ===")
for c, cnt in colors.most_common(20):
    print(f'{c}: {cnt}')

print("\n=== ALL STROKES ===")
for s, cnt in strokes.most_common(10):
    print(f'{s}: {cnt}')

print("\n=== ALL RADII ===")
for r, cnt in radii.most_common(10):
    print(f'{r}: {cnt}')

print("\n=== ALL FONTS ===")
for (fam, sz, wgt), cnt in fonts.most_common(15):
    print(f'{fam} {sz}pt weight={wgt}: {cnt}')

