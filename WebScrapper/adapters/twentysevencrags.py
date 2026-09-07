"""Concrete scraper adapter for 27crags.com (aka The Topo).

Extracts crag → sector → route data from 27crags crag pages.  The main crag
page contains sector cards (``crag-card__title``), and each sector's topo page
at ``/crags/<slug>/topos/<sector-slug>`` contains the route listing.

The route listing page is at ``/crags/<slug>/routelist`` but individual
routes are often loaded via JavaScript.  We parse what is available in the
server-rendered HTML and supplement with regex extraction.

Typical URL patterns:
    https://27crags.com/crags/batu-caves
    https://27crags.com/crags/batu-caves/topos/damai-wall
    https://27crags.com/crags/batu-caves/routelist
"""

from __future__ import annotations

import json
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

_FRENCH_GRADE_RE = re.compile(r"\b([1-9][a-cA-C]\+?)\b")
_HEIGHT_RE = re.compile(r"(\d+(?:\.\d+)?)\s*[mM]\b")
_BOLTS_RE = re.compile(r"(\d+)\s*(?:bolts?|draws?|quickdraws?|B)\b", re.IGNORECASE)

_ROUTE_TYPE_MAP: dict[str, str] = {
    "sport": "sport",
    "trad": "trad",
    "boulder": "boulder",
    "bouldering": "boulder",
    "top rope": "toprope",
    "toprope": "toprope",
    "dws": "dws",
}

_REQUEST_TIMEOUT = 30
_DELAY_BETWEEN_REQUESTS = 1.5

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}

# 27crags stores a ``GRADES_HASH`` mapping in a <script> tag.  The hash maps
# numeric difficulty keys to an array of grades across systems.  Index 4 is
# the French sport grade.
_FRENCH_GRADE_INDEX = 4  # 0=US, 1=Hueco, 2=Aus, 3=Font, 4=French, …


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _fetch(url: str, session: requests.Session) -> BeautifulSoup:
    """GET a URL and return a parsed BeautifulSoup tree."""
    logger.info("Fetching %s", url)
    resp = session.get(url, headers=_HEADERS, timeout=_REQUEST_TIMEOUT)
    resp.raise_for_status()
    return BeautifulSoup(resp.text, "html.parser")


def _clean(text: str | None) -> str | None:
    if not text:
        return None
    return re.sub(r"\s+", " ", text).strip() or None


def _extract_grade(text: str) -> str | None:
    m = _FRENCH_GRADE_RE.search(text)
    return m.group(1) if m else None


def _extract_height(text: str) -> float | None:
    m = _HEIGHT_RE.search(text)
    return float(m.group(1)) if m else None


def _extract_bolts(text: str) -> int | None:
    m = _BOLTS_RE.search(text)
    return int(m.group(1)) if m else None


def _detect_route_type(text: str) -> str | None:
    lower = text.lower()
    for keyword, route_type in _ROUTE_TYPE_MAP.items():
        if keyword in lower:
            return route_type
    return None


# ---------------------------------------------------------------------------
# Grade hash parsing
# ---------------------------------------------------------------------------


def _parse_grades_hash(soup: BeautifulSoup) -> dict[str, str]:
    """Extract the GRADES_HASH from <script> tags.

    Returns a mapping of numeric difficulty key → French grade string.
    """
    grade_map: dict[str, str] = {}

    for script in soup.select("script"):
        text = script.string or ""
        if "GRADES_HASH" not in text:
            continue
        # Extract the JSON object after "GRADES_HASH ="
        m = re.search(r"GRADES_HASH\s*=\s*(\{.+?\})\s*;", text, re.DOTALL)
        if not m:
            continue
        try:
            raw: dict[str, list[str | None]] = json.loads(m.group(1))
            for key, grades in raw.items():
                if (
                    isinstance(grades, list)
                    and len(grades) > _FRENCH_GRADE_INDEX
                    and grades[_FRENCH_GRADE_INDEX]
                ):
                    grade_map[str(key)] = grades[_FRENCH_GRADE_INDEX]
        except (json.JSONDecodeError, IndexError, TypeError):
            logger.debug("Failed to parse GRADES_HASH JSON")
    return grade_map


# ---------------------------------------------------------------------------
# Route extraction from topo / sector pages
# ---------------------------------------------------------------------------

# 27crags topo pages typically have route rows in tables or divs.
_ROUTE_ROW_SELECTORS = [
    "tr.route-row",
    "div.route-row",
    "li.route-item",
    "div.route-item",
    "tr[data-route-id]",
    "div[data-route-id]",
    "div.route-list-item",
    "li.route",
]


def _parse_route_from_row(
    row: Tag, base_url: str, grade_map: dict[str, str]
) -> RouteData | None:
    """Parse a route element into a RouteData model."""

    # --- Route name ---
    name_el = (
        row.select_one(".route-name a")
        or row.select_one("a.route-name")
        or row.select_one(".name a")
        or row.select_one(".route-name")
        or row.select_one("a[href*='/routes/']")
    )
    name = _clean(name_el.get_text()) if name_el else None
    if not name:
        return None

    # --- Source URL ---
    source_url: str | None = None
    link = name_el if name_el and name_el.name == "a" else row.select_one("a[href]")
    if link and link.get("href"):
        source_url = urljoin(base_url, link["href"])

    row_text = row.get_text(separator=" ")

    # --- Grade (try element, then grade_map via data attribute, then regex) ---
    grade: str | None = None

    grade_el = (
        row.select_one(".grade")
        or row.select_one(".grade-text")
        or row.select_one("span.grade")
        or row.select_one("td.grade")
    )
    if grade_el:
        grade = _clean(grade_el.get_text())

    # Try data-grade attribute → grade_map lookup
    if not grade:
        data_grade = row.get("data-grade") or row.get("data-difficulty")
        if data_grade and str(data_grade) in grade_map:
            grade = grade_map[str(data_grade)]

    if not grade:
        grade = _extract_grade(row_text)

    # --- Route type ---
    type_el = row.select_one(".route-type") or row.select_one(".type")
    route_type = (
        _detect_route_type(type_el.get_text())
        if type_el
        else _detect_route_type(row_text)
    )

    # --- Height & bolts ---
    height = _extract_height(row_text)
    bolts = _extract_bolts(row_text)

    return RouteData(
        name=name,
        grade=grade,
        grade_system="french" if grade and _FRENCH_GRADE_RE.match(grade) else None,
        route_type=route_type,
        height_m=height,
        bolts=bolts,
        source_url=source_url,
    )


def _extract_routes_from_page(
    soup: BeautifulSoup, base_url: str, grade_map: dict[str, str]
) -> list[RouteData]:
    """Try multiple selector strategies to find routes on a page."""
    routes: list[RouteData] = []

    for selector in _ROUTE_ROW_SELECTORS:
        rows = soup.select(selector)
        if rows:
            for row in rows:
                route = _parse_route_from_row(row, base_url, grade_map)
                if route:
                    routes.append(route)
            return routes

    # Fallback: look for any table rows
    for tr in soup.select("table tr"):
        route = _parse_route_from_row(tr, base_url, grade_map)
        if route:
            routes.append(route)

    return routes


# ---------------------------------------------------------------------------
# Sector / topo discovery from main crag page
# ---------------------------------------------------------------------------


def _find_sector_cards(
    soup: BeautifulSoup, base_url: str
) -> list[tuple[str, str]]:
    """Return ``[(absolute_url, sector_name), ...]`` from crag-card elements.

    The main crag page shows sectors as cards linking to ``/topos/<sector>``.
    """
    sectors: list[tuple[str, str]] = []
    seen: set[str] = set()

    # Primary: crag-card links with title
    for card in soup.select("a.crag-card--with-summary, a.crag-card"):
        href = card.get("href", "")
        title_el = card.select_one(".crag-card__title")
        name = _clean(title_el.get_text()) if title_el else _clean(card.get_text())
        if not href or not name:
            continue
        abs_url = urljoin(base_url, href)
        if abs_url not in seen:
            seen.add(abs_url)
            sectors.append((abs_url, name))

    # Fallback: look for links containing "/topos/" in the path
    if not sectors:
        for a_tag in soup.select("a[href*='/topos/']"):
            href = a_tag.get("href", "")
            name = _clean(a_tag.get_text())
            if not href or not name:
                continue
            abs_url = urljoin(base_url, href)
            if abs_url not in seen:
                seen.add(abs_url)
                sectors.append((abs_url, name))

    return sectors


def _extract_route_counts(soup: BeautifulSoup) -> dict[str, str]:
    """Extract route type info from data-count-routes attributes.

    Returns a mapping like ``{"Sport": "sport"}`` to help tag routes
    when the per-route type is not available.
    """
    types: dict[str, str] = {}
    for el in soup.select("[data-count-routes]"):
        raw = el.get("data-count-routes", "")
        try:
            data = json.loads(raw)
            for type_name in data:
                normalised = _detect_route_type(type_name)
                if normalised:
                    types[type_name] = normalised
        except (json.JSONDecodeError, TypeError):
            pass
    return types


# ---------------------------------------------------------------------------
# Crag metadata
# ---------------------------------------------------------------------------


def _parse_crag_metadata(
    soup: BeautifulSoup, url: str
) -> dict[str, str | float | None]:
    """Extract crag-level metadata from the page."""
    name = None
    h1 = soup.select_one("h1")
    if h1:
        name = _clean(h1.get_text())
    if not name:
        title_tag = soup.select_one("title")
        name = _clean(title_tag.get_text()) if title_tag else url

    # Coordinates
    lat, lng = None, None
    for script in soup.select("script"):
        text = script.string or ""
        # Look for map initialisation coordinates
        coord_re = re.compile(
            r"(?:lat|latitude)[\"'\s:]+(-?\d{1,3}\.\d{3,8})"
            r".*?(?:lng|lon|longitude)[\"'\s:]+(-?\d{1,3}\.\d{3,8})",
            re.DOTALL,
        )
        m = coord_re.search(text)
        if m:
            try:
                lat, lng = float(m.group(1)), float(m.group(2))
                break
            except ValueError:
                pass

    # Description
    desc_el = soup.select_one(
        'meta[name="description"]'
    ) or soup.select_one('meta[property="og:description"]')
    description = desc_el.get("content") if desc_el else None

    # Country from breadcrumbs or URL
    country = None
    breadcrumbs = soup.select("ol.breadcrumb li a, nav.breadcrumb a")
    if len(breadcrumbs) >= 2:
        country = _clean(breadcrumbs[1].get_text())

    return {
        "name": name,
        "country": country,
        "latitude": lat,
        "longitude": lng,
        "description": _clean(description),
    }


# ---------------------------------------------------------------------------
# Public adapter
# ---------------------------------------------------------------------------


class TwentySevenCragsAdapter(BaseAdapter):
    """Scraper for 27crags.com (The Topo).

    Discovers sectors from crag-card elements on the main crag page, then
    visits each sector's topo page to extract individual routes.

    Usage::

        adapter = TwentySevenCragsAdapter()
        crag = adapter.scrape("https://27crags.com/crags/batu-caves")
    """

    def scrape(self, url: str) -> CragData:
        session = requests.Session()

        soup = _fetch(url, session)
        meta = _parse_crag_metadata(soup, url)
        grade_map = _parse_grades_hash(soup)
        default_types = _extract_route_counts(soup)

        # Determine default route type from summary chart
        default_route_type: str | None = None
        if len(default_types) == 1:
            default_route_type = next(iter(default_types.values()))

        # Discover sector cards on the main page
        sector_links = _find_sector_cards(soup, url)

        sectors: list[SectorData] = []

        if sector_links:
            for sector_url, sector_name in sector_links:
                time.sleep(_DELAY_BETWEEN_REQUESTS)
                try:
                    sector_soup = _fetch(sector_url, session)
                    # Merge grade maps from sector page
                    sector_grades = _parse_grades_hash(sector_soup)
                    merged_grades = {**grade_map, **sector_grades}

                    routes = _extract_routes_from_page(
                        sector_soup, sector_url, merged_grades
                    )

                    # Apply default route type where missing
                    if default_route_type:
                        for route in routes:
                            if not route.route_type:
                                route.route_type = default_route_type

                    sectors.append(SectorData(name=sector_name, routes=routes))
                    logger.info(
                        "Sector '%s': found %d routes",
                        sector_name,
                        len(routes),
                    )
                except requests.RequestException as exc:
                    logger.warning(
                        "Failed to fetch sector '%s' (%s): %s",
                        sector_name,
                        sector_url,
                        exc,
                    )
        else:
            # No sector cards found – try the routelist page
            routelist_url = url.rstrip("/") + "/routelist"
            try:
                time.sleep(_DELAY_BETWEEN_REQUESTS)
                rl_soup = _fetch(routelist_url, session)
                merged_grades = {**grade_map, **_parse_grades_hash(rl_soup)}
                routes = _extract_routes_from_page(
                    rl_soup, routelist_url, merged_grades
                )
                sector_name = meta["name"] or "Main"
                sectors.append(SectorData(name=sector_name, routes=routes))
            except requests.RequestException:
                # Fall back to extracting whatever is on the main page
                routes = _extract_routes_from_page(soup, url, grade_map)
                if routes:
                    sectors.append(
                        SectorData(
                            name=meta["name"] or "Main", routes=routes
                        )
                    )

        logger.info(
            "Scraped crag '%s': %d sectors, %d total routes",
            meta["name"],
            len(sectors),
            sum(len(s.routes) for s in sectors),
        )

        return CragData(
            name=meta["name"],
            country=meta["country"],
            latitude=meta["latitude"],
            longitude=meta["longitude"],
            description=meta["description"],
            source="27crags",
            source_url=url,
            sectors=sectors,
        )

