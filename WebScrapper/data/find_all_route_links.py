import requests
from bs4 import BeautifulSoup
import json
import re

headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
}

url = "https://www.thecrag.com/en/climbing/malaysia/batu-caves/area/13950871"
resp = requests.get(url, headers=headers, timeout=30)
soup = BeautifulSoup(resp.text, "html.parser")

print("=== Checking all script tags for JSON/lists/data ===")
for i, script in enumerate(soup.select("script")):
    text = script.string or ""
    if not text:
        src = script.get("src", "")
        if src:
            print(f"Script {i+1} src: {src}")
        continue
    
    print(f"Script {i+1} length: {len(text)}")
    
    # Check for lists of numbers or objects
    # e.g., arrays of numbers or arrays of objects
    if "data" in text.lower() or "route" in text.lower() or "node" in text.lower():
        print(f"  Matches keyword: data/route/node")
        # Print first 200 characters of the script
        print(f"  Preview: {text[:400]}")
        # Search for any large list/dict pattern
        # Look for something like: var something = [ ... ]; or similar
        vars_found = re.findall(r'(?:var|let|const)\s+(\w+)\s*=\s*(?:\[|\{)', text)
        if vars_found:
            print(f"  Variable declarations: {vars_found}")
        
        # Check for any route IDs in the script. The route IDs we saw earlier: 15703111, 2397654327, 15703381, 2905543335
        for rid in ["15703111", "2397654327", "15703381"]:
            if rid in text:
                print(f"  Contains route ID {rid}!")
                # Print around the route ID
                idx = text.find(rid)
                print(f"    Snippet: {text[max(0, idx-100):idx+200]}")
        print("-" * 40)

