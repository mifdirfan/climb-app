import json
from collections import defaultdict

with open('figma_nodes.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

typo_groups = defaultdict(list)
component_bgs = defaultdict(list)

def to_hex(c):
    r = int(c.get('r', 0) * 255 + 0.5)
    g = int(c.get('g', 0) * 255 + 0.5)
    b = int(c.get('b', 0) * 255 + 0.5)
    return f'#{r:02X}{g:02X}{b:02X}'

def inspect_node(node, path=''):
    name = node.get('name', '')
    n_type = node.get('type')
    curr_path = f'{path} > {name}' if path else name
    
    fills = [f for f in node.get('fills', []) if f.get('visible', True) and f.get('type') == 'SOLID']
    if fills:
        hex_colors = [to_hex(f['color']) for f in fills if 'color' in f]
        component_bgs[name].append({
            'path': curr_path,
            'type': n_type,
            'fills': hex_colors,
            'radius': node.get('cornerRadius') or node.get('rectangleCornerRadii'),
            'strokes': [to_hex(s['color']) for s in node.get('strokes', []) if 'color' in s]
        })

    if n_type == 'TEXT':
        s = node.get('style', {})
        text_fill = None
        for f in node.get('fills', []):
            if f.get('visible', True) and f.get('type') == 'SOLID' and 'color' in f:
                text_fill = to_hex(f['color'])
        
        key = (s.get('fontFamily'), s.get('fontSize'), s.get('fontWeight'), text_fill)
        typo_groups[key].append({
            'text': node.get('characters', '')[:40].replace('\n', ' ').strip(),
            'path': curr_path,
            'lineHeightPx': s.get('lineHeightPx'),
            'letterSpacing': s.get('letterSpacing')
        })

    for child in node.get('children', []):
        inspect_node(child, curr_path)

for nid, ninfo in data.get('nodes', {}).items():
    doc = ninfo.get('document', {})
    inspect_node(doc)

import sys
sys.stdout.reconfigure(encoding='utf-8')

print('=== TYPOGRAPHY ===')
for (font, size, weight, col), samples in sorted(typo_groups.items(), key=lambda x: (x[0][1] or 0), reverse=True):
    sample_texts = [s['text'] for s in samples[:3]]
    lh = samples[0]['lineHeightPx']
    ls = samples[0]['letterSpacing']
    print(f'Font: {font} | Size: {size} | Weight: {weight} | Color: {col} | LH: {lh} | LS: {ls} | Count: {len(samples)}')
    print(f'   Samples: {sample_texts}')

print('\n=== KEY COMPONENTS AND CONTAINERS ===')
key_names = ['Home', 'Sign In', 'Crag Detail', 'Button', 'Input', 'Card', 'Search', 'Route Item', 'Hazard Alert Pill Banner', 'Bottom Navigation', 'Top Bar', 'App Bar', 'Filter', 'Chip', 'Tab']
for name, instances in component_bgs.items():
    if any(k.lower() in name.lower() for k in key_names):
        inst = instances[0]
        print(f'{name:30} : fills={inst["fills"]} radius={inst["radius"]} strokes={inst["strokes"]} count={len(instances)}')
