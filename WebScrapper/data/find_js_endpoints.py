import requests
import re

js_urls = [
    "https://static.thecrag.com/cids/common-1.1.78.js",
    "https://static.thecrag.com/cids/process-1.2.28.js",
    "https://static.thecrag.com/cids/message-1.1.23.js",
    "https://static.thecrag.com/cids/autocomplete-1.1.3.js",
    "https://static.thecrag.com/cids/completions-1.1.23.js",
    "https://static.thecrag.com/cids/area-listview-1.1.37.js",
    "https://static.thecrag.com/cids/maps-1.1.62.js",
    "https://static.thecrag.com/cids/aspectchart-1.1.2.js",
    "https://static.thecrag.com/cids/phototopo-1.1.65.js",
    "https://static.thecrag.com/cids/stream-1.1.21.js",
]

print("=== Searching for endpoints in JS files ===")
for url in js_urls:
    try:
        resp = requests.get(url, timeout=15)
        text = resp.text
        print(f"\nFile: {url} ({len(text)} chars)")
        
        # Search for API, ajax, URL, or JSON endpoints
        # Let's find any occurrences of words ending with a slash or path patterns
        endpoints = re.findall(r'[\'"](?:/api|/routes|/processmap|/oauth|/ajax|/node|/area)/[^\'"]+[\'"]', text)
        if endpoints:
            print("  Found endpoints:")
            for ep in set(endpoints[:20]):
                print(f"    {ep}")
        else:
            print("  No REST-like endpoints found.")
            
        # Search for ajax options
        ajax_calls = re.findall(r'\$\.ajax\s*\(\s*\{[^}]+}', text)
        if ajax_calls:
            print(f"  Found {len(ajax_calls)} $.ajax calls:")
            for call in ajax_calls[:5]:
                print(f"    {call.strip()[:150]}...")
                
    except Exception as e:
        print(f"Failed to fetch {url}: {e}")

