import requests
from bs4 import BeautifulSoup
import re

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
}

# Try fetching using session to see if we can get a non-throttled view
s = requests.Session()
resp = s.get('https://www.thecrag.com/en/climbing/malaysia/batu-caves', headers=headers, timeout=30)
soup = BeautifulSoup(resp.text, 'html.parser')

print("Fetched URL:", resp.url)
print("Title:", soup.title.get_text() if soup.title else "No Title")

# Search for 12483931 in the HTML
html = resp.text
matches = [m.start() for m in re.finditer('12483931', html)]
print(f"Occurrences of 12483931: {len(matches)}")
for m in matches[:5]:
    print(f"  Snippet: {html[max(0, m-100):m+150]}")

