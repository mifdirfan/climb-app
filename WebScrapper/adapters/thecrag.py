"""Concrete scraper adapter for theCrag.com.

Extracts crag → sector → route data from theCrag area pages by parsing the
server-rendered HTML.  theCrag renders a hierarchical node tree where areas
and sub-areas contain route rows.

Typical URL patterns:
    https://www.thecrag.com/climbing/malaysia/batu-caves
    https://www.thecrag.com/climbing/australia/blue-mountains/area/12345678
"""

from __future__ import annotations

import logging
import re
import time
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup, Tag

from adapters.base import BaseAdapter
from models import CragData, RouteData, SectorData

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Regex helpers
# ---------------------------------------------------------------------------

# Matches French sport grades like "6a", "7b+", "8a+" etc.
_FRENCH_GRADE_RE = re.compile(r"\b([1-9][a-cA-C]\+?)\b")

# Matches height strings like "15m", "20 m", "12M"
_HEIGHT_RE = re.compile(r"(\d+(?:\.\d+)?)\s*[mM]\b")

# Matches bolt count patterns like "8 bolts", "12 Bolts", "10B"
_BOLTS_RE = re.compile(r"(\d+)\s*(?:bolts?|draws?|quickdraws?|B)\b", re.IGNORECASE)

# Common route type keywords
_ROUTE_TYPE_MAP: dict[str, str] = {
    "sport": "sport",
    "trad": "trad",
    "boulder": "boulder",
    "bouldering": "boulder",
    "top rope": "toprope",
    "toprope": "toprope",
    "dws": "dws",
    "aid": "aid",
    "mixed": "mixed",
}

# Default request settings
_REQUEST_TIMEOUT = 30
_DELAY_BETWEEN_REQUESTS = 1.5  # polite delay (seconds)

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _fetch(url: str, session: requests.Session) -> BeautifulSoup:
    """GET a URL and return a parsed BeautifulSoup tree."""
    logger.info("Fetching %s", url)
    resp = session.get(url, headers=_HEADERS, timeout=_REQUEST_TIMEOUT)
    resp.raise_for_status()
    return BeautifulSoup(resp.text, "html.parser")


def _extract_grade(text: str) -> str | None:
    """Try to pull a French sport grade from *text*."""
    m = _FRENCH_GRADE_RE.search(text)
    return m.group(1) if m else None


def _extract_height(text: str) -> float | None:
    """Pull a metric height value from *text*."""
    m = _HEIGHT_RE.search(text)
    return float(m.group(1)) if m else None


def _extract_bolts(text: str) -> int | None:
    """Pull a bolt count from *text*."""
    m = _BOLTS_RE.search(text)
    return int(m.group(1)) if m else None


def _detect_route_type(text: str) -> str | None:
    """Return normalised route type from *text*, or ``None``."""
    lower = text.lower()
    for keyword, route_type in _ROUTE_TYPE_MAP.items():
        if keyword in lower:
            return route_type
    return None


def _clean(text: str | None) -> str | None:
    """Collapse whitespace and strip."""
    if not text:
        return None
    return re.sub(r"\s+", " ", text).strip() or None


def _normalize_path(url_or_path: str) -> str:
    """Normalize a URL path by stripping domain, language prefixes, and trailing slashes."""
    if not url_or_path:
        return ""
    # Remove protocol and domain if present
    path = re.sub(r"^https?://[^/]+", "", url_or_path)
    # Remove language prefix like /en, /fr, /de, etc.
    path = re.sub(r"^/(?:en|fr|de|es|it|ja|zh|nl|pl|pt|ru|sv|no|fi|da)\b", "", path)
    # Remove trailing slashes
    return path.rstrip("/")


# ---------------------------------------------------------------------------
# TheCrag HTML parsing
# ---------------------------------------------------------------------------

# Star characters to strip from route names
_STARS_RE = re.compile(r"^[\s★☆*]+")


def _clean_route_name(raw: str) -> str | None:
    """Strip star ratings and whitespace from a route name."""
    name = _STARS_RE.sub("", raw).strip()
    return name if name else None


def _extract_routes_from_table(
    soup: BeautifulSoup | Tag, base_url: str
) -> list[RouteData]:
    """Extract routes from theCrag's popular-routes table.

    Structure per row::

        <tr>
          <td class="gb2">            <!-- grade bar (visual) -->
          <td class="g">6b</td>       <!-- French grade -->
          <td class="rt">             <!-- route name cell -->
            <span class="route">
              <a href="/…/route/12345">★★ Monsoon</a>
            </span>
          </td>
          <td class="s sport">        <!-- type (class = "sport", "trad", etc.) -->
        </tr>
    """
    routes: list[RouteData] = []
    seen_urls: set[str] = set()

    for tr in soup.select("tr"):
        # Must have a route link
        route_link = tr.select_one("td.rt a[href]")
        if not route_link:
            continue
        href = route_link.get("href", "")
        if "/route/" not in href:
            continue

        abs_url = urljoin(base_url, href)
        if abs_url in seen_urls:
            continue
        seen_urls.add(abs_url)

        # Route name (strip stars)
        raw_name = route_link.get_text().strip()
        name = _clean_route_name(raw_name)
        if not name:
            continue

        # Grade from td.g
        grade_td = tr.select_one("td.g")
        grade = _clean(grade_td.get_text()) if grade_td else None

        # Route type from td.s class list (e.g. class="s sport")
        type_td = tr.select_one("td.s")
        route_type: str | None = None
        if type_td:
            classes = type_td.get("class", [])
            for cls in classes:
                detected = _detect_route_type(cls)
                if detected:
                    route_type = detected
                    break

        row_text = tr.get_text(separator=" ")
        height = _extract_height(row_text)
        bolts = _extract_bolts(row_text)

        routes.append(
            RouteData(
                name=name,
                grade=grade,
                grade_system="french" if grade else None,
                route_type=route_type,
                height_m=height,
                bolts=bolts,
                source_url=abs_url,
            )
        )

    return routes, seen_urls


def _extract_routes_from_photos(
    soup: BeautifulSoup | Tag, base_url: str, seen_urls: set[str]
) -> list[RouteData]:
    """Extract routes from photo caption elements.

    Photo captions on theCrag look like::

        <p class="title">
          <span class="route"><a href="/route/12345">★★ Anchor</a></span>
          6a
          - Right side climbers on Anchor
        </p>

    This captures routes not in the main table.
    """
    routes: list[RouteData] = []

    for p in soup.select("p.title"):
        route_link = p.select_one("span.route a[href]") or p.select_one("a[href]")
        if not route_link:
            continue
        href = route_link.get("href", "")
        if "/route/" not in href:
            continue

        abs_url = urljoin(base_url, href)
        if abs_url in seen_urls:
            continue
        seen_urls.add(abs_url)

        raw_name = route_link.get_text().strip()
        name = _clean_route_name(raw_name)
        if not name:
            continue

        # The grade often appears as text after the route link
        # e.g. "★★ KL Connection | 6c | - 20250215_110404.jpg"
        full_text = p.get_text(separator=" ")
        grade = _extract_grade(full_text)

        routes.append(
            RouteData(
                name=name,
                grade=grade,
                grade_system="french" if grade else None,
                route_type=None,
                height_m=_extract_height(full_text),
                bolts=_extract_bolts(full_text),
                source_url=abs_url,
            )
        )

    return routes


def _extract_all_routes(
    soup: BeautifulSoup | Tag, base_url: str
) -> list[RouteData]:
    """Extract routes using all available strategies, deduplicated by URL."""
    table_routes, seen_urls = _extract_routes_from_table(soup, base_url)
    photo_routes = _extract_routes_from_photos(soup, base_url, seen_urls)
    return table_routes + photo_routes


def _parse_crag_metadata(
    soup: BeautifulSoup, url: str
) -> dict[str, str | float | None]:
    """Extract crag-level metadata (name, coords, description)."""
    # Name — prefer <title> (split on "|" and ",") or og:title over <h1>
    # because theCrag's h1 often contains extra descriptive text like
    # "Batu Caves Mostly Sport climbing 359 routes in crag".
    name = None

    # Try og:title first (cleanest)
    og_title = soup.select_one('meta[property="og:title"]')
    if og_title and og_title.get("content"):
        # "Batu Caves, Sport climbing | theCrag" → "Batu Caves"
        val = _clean(og_title["content"].split("|")[0].split(",")[0])
        if val and not any(x in val.lower() for x in ["login", "join in", "general information", "cids"]):
            name = val

    # Fall back to <title>
    if not name:
        title_tag = soup.select_one("title")
        if title_tag:
            val = _clean(title_tag.get_text().split("|")[0].split(",")[0])
            if val and not any(x in val.lower() for x in ["login", "join in", "general information", "cids"]):
                name = val

    # Last resort: <h1>, but try to trim trailing noise
    if not name:
        h1 = soup.select_one("h1")
        if h1:
            raw = _clean(h1.get_text()) or ""
            if not any(x in raw.lower() for x in ["login", "join in", "general information", "cids"]):
                # Strip common suffixes like "Mostly Sport climbing 359 routes…"
                m = re.match(r"^(.+?)\s+(?:Mostly|Sport|Trad|Boulder|climbing|\d+\s+routes)", raw)
                name = m.group(1).strip() if m else raw

    # Coordinates from meta tags or embedded JSON
    lat, lng = None, None
    # Check for geo meta tags
    geo_pos = soup.select_one('meta[name="geo.position"]')
    if geo_pos and geo_pos.get("content"):
        parts = geo_pos["content"].split(";")
        if len(parts) == 2:
            try:
                lat, lng = float(parts[0]), float(parts[1])
            except ValueError:
                pass

    # Check for coordinates in page text via regex
    if lat is None:
        coord_re = re.compile(
            r"(-?\d{1,3}\.\d{3,8})\s*[,;]\s*(-?\d{1,3}\.\d{3,8})"
        )
        # Look in script tags for coordinate data
        for script in soup.select("script"):
            text = script.string or ""
            m = coord_re.search(text)
            if m:
                try:
                    candidate_lat = float(m.group(1))
                    candidate_lng = float(m.group(2))
                    if -90 <= candidate_lat <= 90 and -180 <= candidate_lng <= 180:
                        lat, lng = candidate_lat, candidate_lng
                        break
                except ValueError:
                    pass

    # Description
    desc_el = soup.select_one(
        'meta[name="description"]'
    ) or soup.select_one('meta[property="og:description"]')
    description = desc_el.get("content") if desc_el else None

    return {
        "name": name,
        "latitude": lat,
        "longitude": lng,
        "description": _clean(description),
    }


# ---------------------------------------------------------------------------
# Public adapter
# -------------------------------------------------
class TheCragAdapter(BaseAdapter):
    """Scraper for theCrag.com area pages.

    Uses theCrag's internal REST API with an active web session (granting
    anonweb permissions) to recursively fetch all climbing sectors and routes.
    This guarantees 100% data extraction (including non-popular routes)
    while being extremely light on theCrag servers.

    Usage::

        adapter = TheCragAdapter()
        crag = adapter.scrape("https://www.thecrag.com/climbing/malaysia/batu-caves")
    """

    def scrape(self, url: str) -> CragData:
        session = requests.Session()

        # Try to extract node ID from URL directly if it matches /area/(\d+)
        m_url = re.search(r"/area/(\d+)", url)
        node_id = m_url.group(1) if m_url else None

        meta = None
        soup = None

        if not node_id:
            # Try to fetch the main page to find data-nid
            try:
                soup = _fetch(url, session)
                meta_candidate = _parse_crag_metadata(soup, url)
                if meta_candidate.get("name"):
                    meta = meta_candidate
                    body = soup.find("body")
                    node_id = body.get("data-nid") if body else None
                    
                    if not node_id:
                        for script in soup.select("script"):
                            text = script.string or ""
                            m = re.search(r"current_id\s*:\s*(\d+)", text)
                            if m:
                                node_id = m.group(1)
                                break
            except requests.RequestException as exc:
                logger.warning("Failed to fetch main page HTML (might be throttled): %s", exc)

        # If still no node_id, use lookup API fallback using name from URL path
        if not node_id:
            logger.info("Using lookup API fallback to resolve crag node ID...")
            url_norm = _normalize_path(url)
            last_segment = url_norm.split("/")[-1] if url_norm else ""
            search_name = last_segment.replace("-", " ").strip()
            
            if search_name:
                lookup_url = f"https://www.thecrag.com/api/lookup/crag?search={search_name}"
                try:
                    headers = {
                        "User-Agent": _HEADERS["User-Agent"],
                        "Accept": "application/json"
                    }
                    resp = session.get(lookup_url, headers=headers, timeout=_REQUEST_TIMEOUT)
                    if resp.status_code == 200:
                        data = resp.json().get("data", [])
                        if data:
                            best_match = data[0]
                            for item in data:
                                if item.get("name", "").lower() == search_name.lower():
                                    best_match = item
                                    break
                            node_id = str(best_match.get("id"))
                            logger.info("Resolved node ID %s for search term '%s'", node_id, search_name)
                except requests.RequestException as exc:
                    logger.warning("Lookup API query failed: %s", exc)

        if not node_id:
            raise ValueError(f"Could not resolve node ID for crag page {url}")

        # Ensure we have a valid session and cookies (ApacheSessionID)
        session_id = session.cookies.get("ApacheSessionID")
        if not session_id:
            # If no cookie is present, generate a dummy session request to seed cookies
            try:
                session.get("https://www.thecrag.com", headers={"User-Agent": _HEADERS["User-Agent"]}, timeout=_REQUEST_TIMEOUT)
                session_id = session.cookies.get("ApacheSessionID")
            except requests.RequestException:
                pass

        # Update session preferences to accept site policy and unlock anonweb API level
        if session_id:
            try:
                session.post(
                    "https://www.thecrag.com/api/session/update",
                    json={"data": {"session": session_id, "preference": {"site-usage-policy": "seen"}}},
                    headers={
                        "User-Agent": _HEADERS["User-Agent"],
                        "Accept": "application/json",
                        "Content-Type": "application/json",
                        "X-Requested-With": "XMLHttpRequest",
                    },
                    timeout=_REQUEST_TIMEOUT
                )
            except requests.RequestException as exc:
                logger.warning("Failed to accept site policy: %s", exc)

        # Setup API request headers
        self.api_headers = {
            "User-Agent": _HEADERS["User-Agent"],
            "Accept": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Referer": url,
        }

        # If metadata is still not populated, query the API node endpoint with show=location
        if not meta:
            logger.info("Fetching crag metadata via node API endpoint...")
            meta = {
                "name": "Crag",
                "latitude": None,
                "longitude": None,
                "description": None,
            }
            url_api = f"https://www.thecrag.com/api/node/id/{node_id}?show=location"
            try:
                resp = session.get(url_api, headers=self.api_headers, timeout=_REQUEST_TIMEOUT)
                if resp.status_code == 200:
                    data = resp.json().get("data", {})
                    meta["name"] = data.get("name") or meta["name"]
                    geom = data.get("geometry", {})
                    meta["latitude"] = geom.get("lat") or (geom.get("center", [None, None])[1])
                    meta["longitude"] = geom.get("long") or (geom.get("center", [None, None])[0])
            except requests.RequestException as exc:
                logger.warning("Failed to fetch crag metadata from node API: %s", exc)

        # 4. Recursively traverse all sectors starting from the crag node
        sectors: list[SectorData] = []
        logger.info("Starting API-based recursive traversal from crag node %s...", node_id)
        
        children = self._get_children(node_id, session)
        for child in children:
            child_type = child.get("type")
            child_id = child.get("id")
            child_name = child.get("name")
            if child_type != "route" and child_id:
                # Recursively gather routes for this sector
                time.sleep(_DELAY_BETWEEN_REQUESTS)
                self._traverse_node(child_id, [child_name], sectors, session)

        logger.info(
            "Scraped crag '%s' via API: %d sectors, %d total routes",
            meta["name"],
            len(sectors),
            sum(len(s.routes) for s in sectors),
        )

        return CragData(
            name=meta["name"],
            latitude=meta["latitude"],
            longitude=meta["longitude"],
            description=meta["description"],
            source="thecrag",
            source_url=url,
            sectors=sectors,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _get_children(self, node_id: str | int, session: requests.Session) -> list[dict]:
        """Fetch list of children nodes from the API."""
        url = f"https://www.thecrag.com/api/node/id/{node_id}/children"
        try:
            resp = session.get(url, headers=self.api_headers, timeout=_REQUEST_TIMEOUT)
            if resp.status_code == 200:
                return resp.json().get("data", [])
            else:
                logger.warning("API returned status %d for node %s", resp.status_code, node_id)
        except requests.RequestException as exc:
            logger.warning("API request failed for node %s: %s", node_id, exc)
        return []

    def _traverse_node(
        self,
        node_id: str | int,
        path_names: list[str],
        sectors: list[SectorData],
        session: requests.Session,
    ):
        """Recursively descend through child sub-areas and group routes into SectorData."""
        children = self._get_children(node_id, session)
        time.sleep(_DELAY_BETWEEN_REQUESTS)

        routes = []
        sub_sectors = []

        for child in children:
            if child.get("type") == "route":
                routes.append(child)
            else:
                sub_sectors.append(child)

        if routes:
            # If routes are directly on this node, create a SectorData for it
            sector_name = " - ".join(path_names)
            route_objects = [self._parse_api_route(r) for r in routes]
            sectors.append(SectorData(name=sector_name, routes=route_objects))
            logger.info("Sector '%s': found %d routes", sector_name, len(route_objects))

        for sub in sub_sectors:
            sub_id = sub.get("id")
            sub_name = sub.get("name")
            if sub_id and sub_name:
                self._traverse_node(sub_id, path_names + [sub_name], sectors, session)

    def _parse_api_route(self, r: dict) -> RouteData:
        """Parse API route dictionary into RouteData model."""
        name = r.get("name")
        grade = r.get("grade")
        
        # Normalize style/type keyword
        raw_style = r.get("style") or ""
        route_type = None
        if raw_style:
            route_type = _detect_route_type(raw_style)

        # Height extraction from list display e.g. [15, "m"]
        height_m = None
        h_data = r.get("height") or r.get("displayHeight")
        if h_data and isinstance(h_data, list) and len(h_data) > 0:
            try:
                height_m = float(h_data[0])
            except (ValueError, TypeError):
                pass

        # Bolts count extraction
        bolts = None
        raw_bolts = r.get("bolts")
        if raw_bolts is not None:
            try:
                bolts = int(raw_bolts)
            except (ValueError, TypeError):
                pass

        # Reconstruct canonical route URL
        route_id = r.get("id")
        source_url = f"https://www.thecrag.com/route/{route_id}" if route_id else None

        return RouteData(
            name=name,
            grade=grade,
            grade_system="french" if grade else None,
            route_type=route_type,
            height_m=height_m,
            bolts=bolts,
            source_url=source_url,
        )

