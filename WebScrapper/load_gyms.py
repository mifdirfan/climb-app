"""Load gyms.csv into the public.crags table (venue_type='indoor').

Usage:
    python load_gyms.py --csv data/gyms.csv

Requires DATABASE_URL in environment or a .env file, e.g.:
    DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
"""

from __future__ import annotations

import argparse
import csv
import json
import logging
import os
import re
import sys
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(message)s")
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Pricing parser
# ---------------------------------------------------------------------------

_PRICE_RE = re.compile(r"RM\s*(\d+(?:\.\d+)?)\s*(?:\(([^)]+)\))?", re.IGNORECASE)


def parse_pricing(text: str) -> list[dict]:
    """Convert free-text pricing string into structured list.

    Input:  "Day Pass RM25 (Student) RM35 (Adult), 1 Month RM150, Shoes RM5"
    Output: [
        {"category": "Day Pass", "label": "Student", "price": 25},
        {"category": "Day Pass", "label": "Adult",   "price": 35},
        {"category": "1 Month",  "label": "1 Month", "price": 150},
        {"category": "Shoes",    "label": "Shoes",   "price": 5},
    ]
    """
    if not text or not text.strip():
        return []

    result: list[dict] = []

    for entry in text.split(","):
        entry = entry.strip()
        if not entry:
            continue

        first_rm = re.search(r"RM", entry, re.IGNORECASE)
        if not first_rm:
            continue

        category = entry[: first_rm.start()].strip().rstrip("(").strip()
        if not category:
            continue

        for price_str, label in _PRICE_RE.findall(entry):
            price = float(price_str) if "." in price_str else int(price_str)
            result.append(
                {
                    "category": category,
                    "label": label.strip() if label else category,
                    "price": price,
                }
            )

    return result


# ---------------------------------------------------------------------------
# CSV helpers
# ---------------------------------------------------------------------------


def _pipe_to_array(value: str) -> list[str]:
    """Split a pipe-separated string into a cleaned list."""
    if not value or not value.strip():
        return []
    return [v.strip() for v in value.split("|") if v.strip()]


def _float_or_none(value: str) -> float | None:
    try:
        return float(value) if value and value.strip() else None
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# DB upsert
# ---------------------------------------------------------------------------

_UPSERT_SQL = """
INSERT INTO public.crags (
    name, venue_type, state, city, address,
    latitude, longitude,
    operating_hours, pricing,
    website, instagram, facebook, phone,
    photos, wall_types
) VALUES (
    %(name)s, 'indoor', %(state)s, %(city)s, %(address)s,
    %(latitude)s, %(longitude)s,
    %(operating_hours)s, %(pricing)s,
    %(website)s, %(instagram)s, %(facebook)s, %(phone)s,
    %(photos)s, %(wall_types)s
)
ON CONFLICT (name, state)
DO UPDATE SET
    city             = EXCLUDED.city,
    address          = EXCLUDED.address,
    latitude         = EXCLUDED.latitude,
    longitude        = EXCLUDED.longitude,
    operating_hours  = EXCLUDED.operating_hours,
    pricing          = EXCLUDED.pricing,
    website          = EXCLUDED.website,
    instagram        = EXCLUDED.instagram,
    facebook         = EXCLUDED.facebook,
    phone            = EXCLUDED.phone,
    photos           = EXCLUDED.photos,
    wall_types       = EXCLUDED.wall_types;
"""


def load_gyms(csv_path: Path, conn) -> int:
    """Read gyms CSV and upsert each row into public.crags. Returns row count."""
    count = 0
    with csv_path.open(encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        with conn.cursor() as cur:
            for row in reader:
                pricing = parse_pricing(row.get("pricing", ""))
                params = {
                    "name": row["gym_name"].strip(),
                    "state": row.get("gym_state", "").strip() or None,
                    "city": row.get("gym_city", "").strip() or None,
                    "address": row.get("gym_address", "").strip() or None,
                    "latitude": _float_or_none(row.get("gym_latitude", "")),
                    "longitude": _float_or_none(row.get("gym_longitude", "")),
                    "operating_hours": row.get("operating_hours", "").strip() or None,
                    "pricing": psycopg2.extras.Json(pricing),
                    "website": row.get("website", "").strip() or None,
                    "instagram": row.get("instagram", "").strip() or None,
                    "facebook": row.get("facebook", "").strip() or None,
                    "phone": row.get("phone", "").strip() or None,
                    "photos": _pipe_to_array(row.get("photos", "")) or None,
                    "wall_types": _pipe_to_array(row.get("wall_types", "")) or None,
                }
                cur.execute(_UPSERT_SQL, params)
                logger.info("Upserted: %s", params["name"])
                count += 1
        conn.commit()
    return count


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Load gyms CSV into Supabase.")
    parser.add_argument("--csv", default="data/gyms.csv", help="Path to gyms.csv")
    args = parser.parse_args(argv)

    csv_path = Path(args.csv)
    if not csv_path.is_file():
        print(f"Error: CSV not found: {csv_path}", file=sys.stderr)
        return 1

    db_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:54322/postgres")
    try:
        conn = psycopg2.connect(db_url)
    except Exception as exc:
        print(f"Error: could not connect to database: {exc}", file=sys.stderr)
        return 1

    try:
        count = load_gyms(csv_path, conn)
        print(f"\n[OK] Loaded {count} gyms into public.crags.\n")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
