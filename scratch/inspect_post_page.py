import json, sys

sys.stdout.reconfigure(encoding='utf-8')

with open('../scratch/post_page_raw.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

def to_hex(c):
    if not c: return ''
    r = int(c.get('r', 0) * 255 + 0.5)
    g = int(c.get('g', 0) * 255 + 0.5)
    b = int(c.get('b', 0) * 255 + 0.5)
    return f'#{r:02X}{g:02X}{b:02X}'

def detail(node, depth=0):
    if not isinstance(node, dict):
        return
    indent = '  ' * depth
    name = node.get('name', '')
    ntype = node.get('type', '')
    box = node.get('absoluteBoundingBox', {}) or {}
    w, h = box.get('width', 0), box.get('height', 0)
    
    extra = []
    if node.get('layoutMode'):
        extra.append(f"layout={node.get('layoutMode')} pad=({node.get('paddingTop')},{node.get('paddingRight')},{node.get('paddingBottom')},{node.get('paddingLeft')}) gap={node.get('itemSpacing')} align=({node.get('primaryAxisAlignItems')},{node.get('counterAxisAlignItems')})")
    if node.get('cornerRadius'):
        extra.append(f"radius={node.get('cornerRadius')}")
    if node.get('rectangleCornerRadii'):
        extra.append(f"radii={node.get('rectangleCornerRadii')}")
    
    fills = [f for f in node.get('fills', []) if isinstance(f, dict) and f.get('visible', True)]
    if fills:
        fill_types = [f"{f.get('type')}:{to_hex(f.get('color'))}" for f in fills if 'color' in f]
        extra.append(f"fills={fill_types}")
        
    strokes = [s for s in node.get('strokes', []) if isinstance(s, dict) and s.get('visible', True)]
    if strokes:
        stroke_types = [f"{s.get('type')}:{to_hex(s.get('color'))}" for s in strokes if 'color' in s]
        extra.append(f"strokes={stroke_types} weight={node.get('strokeWeight')}")

    if ntype == 'TEXT':
        st = node.get('style', {})
        txt = node.get('characters', '').replace('\n', '\\n')
        extra.append(f"font='{st.get('fontFamily')}' {st.get('fontSize')}pt w={st.get('fontWeight')} text='{txt}'")

    print(f"{indent}- {name} [{ntype}] ({w:.0f}x{h:.0f}) {' '.join(extra)}")
    
    children = node.get('children')
    if isinstance(children, list):
        for c in children:
            detail(c, depth + 1)

nodes = d.get('nodes', {})
for nid, ninfo in nodes.items():
    doc = ninfo.get('document', {})
    detail(doc)

