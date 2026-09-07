import requests
import time
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
}

s = requests.Session()

# 1. Fetch main page for cookies
print("Fetching main crag page...")
r1 = s.get('https://www.thecrag.com/climbing/malaysia/batu-caves', headers=headers, timeout=30)
session_id = s.cookies.get('ApacheSessionID')
print("Session ID:", session_id)

# 2. Update preference to get anonweb access
print("Accepting site usage policy...")
s.post('https://www.thecrag.com/api/session/update',
       json={'data': {'session': session_id, 'preference': {'site-usage-policy': 'seen'}}},
       headers={**headers, 'Accept': 'application/json', 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest'},
       timeout=30)

api_headers = {
    **headers,
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': 'https://www.thecrag.com/climbing/malaysia/batu-caves'
}

def get_children(node_id):
    url = f"https://www.thecrag.com/api/node/id/{node_id}/children"
    resp = s.get(url, headers=api_headers, timeout=30)
    if resp.status_code == 200:
        return resp.json().get('data', [])
    else:
        print(f"Error fetching children for {node_id}: {resp.status_code} - {resp.text}")
        return []

all_routes = []

def traverse(node_id, path_names):
    print(f"Traversing node {node_id} ({' -> '.join(path_names)})...")
    children = get_children(node_id)
    time.sleep(1.0) # Polite delay
    
    sub_sectors = []
    routes = []
    
    for child in children:
        child_type = child.get('type')
        if child_type == 'route':
            routes.append(child)
        else:
            sub_sectors.append(child)
            
    print(f"  Found {len(routes)} routes and {len(sub_sectors)} sub-sectors.")
    
    for r in routes:
        # Extract height
        h_val = None
        h_data = r.get('height') or r.get('displayHeight')
        if h_data and isinstance(h_data, list) and len(h_data) > 0:
            try:
                h_val = float(h_data[0])
            except ValueError:
                pass
        
        all_routes.append({
            'sector_path': path_names,
            'name': r.get('name'),
            'grade': r.get('grade'),
            'style': r.get('style'),
            'bolts': r.get('bolts'),
            'height_m': h_val,
            'id': r.get('id'),
            'urlAncestorStub': r.get('urlAncestorStub')
        })
        
    for sub in sub_sectors:
        traverse(sub.get('id'), path_names + [sub.get('name')])

# Start traversal from Batu Caves main node
traverse("12483931", [])

print(f"\nDone! Found {len(all_routes)} total routes.")
# Print first 20 routes
for r in all_routes[:20]:
    print(r)

