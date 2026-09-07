import requests
from bs4 import BeautifulSoup

headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
}

url = "https://www.thecrag.com/en/article/api"
print(f"Fetching API documentation from {url}...")
resp = requests.get(url, headers=headers, timeout=30)
soup = BeautifulSoup(resp.text, "html.parser")

# Write parsed text or markdown to a file
with open("data/api_doc.txt", "w", encoding="utf-8") as f:
    # Print clean page title and header
    f.write(f"Title: {soup.title.get_text() if soup.title else 'No Title'}\n")
    f.write(f"URL: {url}\n")
    f.write("="*80 + "\n\n")
    
    # Get main article content or the whole body text
    content_div = soup.select_one("div.article-content") or soup.select_one("div#content") or soup.select_one("body")
    if content_div:
        f.write(content_div.get_text(separator="\n"))
    else:
        f.write(soup.get_text(separator="\n"))

print("API documentation written to data/api_doc.txt")

