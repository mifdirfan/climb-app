import requests
import json

s = requests.Session()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
}
s.get('https://www.thecrag.com/climbing/malaysia/batu-caves', headers=headers, timeout=30)
session_id = s.cookies.get('ApacheSessionID')
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
r = s.get('https://www.thecrag.com/api/node/id/15705937/children', headers=api_headers, timeout=30)
data = r.json()

for i, item in enumerate(data['data']):
    print(f"Route {i+1}: {item.get('name')}")
    print(f"  bolts: {item.get('bolts')}")
    print(f"  height: {item.get('height')}")
    print(f"  displayHeight: {item.get('displayHeight')}")
    print(f"  style: {item.get('style')}")
    print(f"  gradeStyle: {item.get('gradeStyle')}")
    print(f"  grade: {item.get('grade')}")
    print(f"  stars: {item.get('stars')}")
    print(f"  urlAncestorStub: {item.get('urlAncestorStub')}")
    print()

