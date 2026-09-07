"""Read a reviewed CSV file and insert relational rows into PostgreSQL.

The CSV is the flat, denormalised format produced by
``exporters.csv_exporter``.  This loader re-normalises it into three tables::

    public.crags   (id UUID PK, name, country, region, latitude, longitude,
                    description, source, source_url, created_at)

    public.sectors (id UUID PK, crag_id UUID FK → crags, name, description,
                    approach_info, sort_order, created_at)

    public.routes  (id UUID PK, sector_id UUID FK → sectors, name, grade,
                    grade_system, route_type, height_m, bolts, description,
                    source_url, sort_order, created_at)

Tables and the ``uuid-ossp`` extension are created automatically if they
don't already exist (idempotent DDL).

Connection is configured via the ``DATABASE_URL`` environment variable
(loaded from ``.env`` by ``python-dotenv``).
"""

from __future__ import annotations

import csv
import logging
import os
import uuid
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# DDL – idempotent table creation
# ---------------------------------------------------------------------------

_DDL = """\
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.crags (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    country     TEXT,
    region      TEXT,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    description TEXT,
    source      TEXT,
    source_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (name, source_url)
);

CREATE TABLE IF NOT EXISTS public.sectors (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crag_id        UUID NOT NULL REFERENCES public.crags(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    description    TEXT,
    approach_info  TEXT,
    sort_order     INTEGER NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (crag_id, name)
);

CREATE TABLE IF NOT EXISTS public.routes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sector_id     UUID NOT NULL REFERENCES public.sectors(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    grade         TEXT,
    grade_system  TEXT,
    route_type    TEXT,
    height_m      DOUBLE PRECISION,
    bolts         INTEGER,
    description   TEXT,
    source_url    TEXT,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (sector_id, name)
);
"""

# ---------------------------------------------------------------------------
# Upsert SQL
# ---------------------------------------------------------------------------

_UPSERT_CRAG = """\
INSERT INTO public.crags (id, name, country, region, latitude, longitude,
                          description, source, source_url)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
ON CONFLICT (name, source_url) DO UPDATE SET
    country     = COALESCE(EXCLUDED.country,     public.crags.country),
    region      = COALESCE(EXCLUDED.region,      public.crags.region),
    latitude    = COALESCE(EXCLUDED.latitude,     public.crags.latitude),
    longitude   = COALESCE(EXCLUDED.longitude,    public.crags.longitude),
    description = COALESCE(EXCLUDED.description,  public.crags.description),
    source      = COALESCE(EXCLUDED.source,       public.crags.source)
RETURNING id;
"""

_UPSERT_SECTOR = """\
INSERT INTO public.sectors (id, crag_id, name, description, approach_info, sort_order)
VALUES (%s, %s, %s, %s, %s, %s)
ON CONFLICT (crag_id, name) DO UPDATE SET
    description   = COALESCE(EXCLUDED.description,   public.sectors.description),
    approach_info = COALESCE(EXCLUDED.approach_info,  public.sectors.approach_info),
    sort_order    = EXCLUDED.sort_order
RETURNING id;
"""

_UPSERT_ROUTE = """\
INSERT INTO public.routes (id, sector_id, name, grade, grade_system,
                           route_type, height_m, bolts, description,
                           source_url, sort_order)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
ON CONFLICT (sector_id, name) DO UPDATE SET
    grade        = COALESCE(EXCLUDED.grade,        public.routes.grade),
    grade_system = COALESCE(EXCLUDED.grade_system,  public.routes.grade_system),
    route_type   = COALESCE(EXCLUDED.route_type,    public.routes.route_type),
    height_m     = COALESCE(EXCLUDED.height_m,      public.routes.height_m),
    bolts        = COALESCE(EXCLUDED.bolts,         public.routes.bolts),
    description  = COALESCE(EXCLUDED.description,   public.routes.description),
    source_url   = COALESCE(EXCLUDED.source_url,    public.routes.source_url),
    sort_order   = EXCLUDED.sort_order
RETURNING id;
"""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_database_url() -> str:
    """Load DATABASE_URL from environment / .env file."""
    load_dotenv()
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set.  "
            "Add it to your .env file or export it as an environment variable.\n"
            "Example: DATABASE_URL=postgresql://user:password@localhost:5432/climbmy"
        )
    return url


def _to_float(value: str | None) -> float | None:
    """Safely convert a CSV cell to float."""
    if not value or value.strip() == "":
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def _to_int(value: str | None) -> int | None:
    """Safely convert a CSV cell to int."""
    if not value or value.strip() == "":
        return None
    try:
        return int(float(value))  # handles "8.0" from CSV
    except (ValueError, TypeError):
        return None


def _blank_to_none(value: str | None) -> str | None:
    """Return ``None`` for empty / whitespace-only strings."""
    if not value or value.strip() == "":
        return None
    return value.strip()


# ---------------------------------------------------------------------------
# Core loader
# ---------------------------------------------------------------------------


def _read_csv(path: Path) -> list[dict[str, str]]:
    """Read the CSV into a list of row dicts."""
    with path.open("r", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
    if not rows:
        raise ValueError(f"CSV file is empty: {path}")
    logger.info("Read %d rows from %s", len(rows), path)
    return rows


def load_csv_to_db(csv_path: str | Path) -> dict[str, int]:
    """Read a reviewed CSV and insert/upsert rows into PostgreSQL.

    Parameters
    ----------
    csv_path:
        Path to the flat CSV file (produced by ``exporters.csv_exporter``).

    Returns
    -------
    dict
        Counts of inserted/updated entities: ``{"crags": N, "sectors": N, "routes": N}``.
    """
    csv_path = Path(csv_path)
    if not csv_path.is_file():
        raise FileNotFoundError(f"CSV file not found: {csv_path}")

    rows = _read_csv(csv_path)
    db_url = _get_database_url()

    # Track upsert counts
    crag_count = 0
    sector_count = 0
    route_count = 0

    # Caches: (crag_name, crag_source_url) → UUID,  (crag_id, sector_name) → UUID
    crag_cache: dict[tuple[str | None, str | None], uuid.UUID] = {}
    sector_cache: dict[tuple[uuid.UUID, str | None], uuid.UUID] = {}

    # Sector ordering per crag, route ordering per sector
    sector_order: dict[uuid.UUID, int] = {}   # crag_id → next index
    route_order: dict[uuid.UUID, int] = {}     # sector_id → next index

    conn = psycopg2.connect(db_url)
    try:
        with conn:
            with conn.cursor() as cur:
                # Ensure tables exist
                cur.execute(_DDL)
                logger.info("DDL applied (tables created if needed)")

                for row in rows:
                    # ----- Crag -----
                    crag_name = _blank_to_none(row.get("crag_name"))
                    crag_source_url = _blank_to_none(row.get("crag_source_url"))
                    crag_key = (crag_name, crag_source_url)

                    if crag_key not in crag_cache:
                        crag_id = uuid.uuid4()
                        cur.execute(
                            _UPSERT_CRAG,
                            (
                                str(crag_id),
                                crag_name,
                                _blank_to_none(row.get("crag_country")),
                                _blank_to_none(row.get("crag_region")),
                                _to_float(row.get("crag_latitude")),
                                _to_float(row.get("crag_longitude")),
                                None,  # crag description not in CSV columns
                                _blank_to_none(row.get("crag_source")),
                                crag_source_url,
                            ),
                        )
                        returned = cur.fetchone()
                        crag_id = returned[0] if returned else crag_id
                        # Normalise to uuid.UUID if returned as string
                        if isinstance(crag_id, str):
                            crag_id = uuid.UUID(crag_id)
                        crag_cache[crag_key] = crag_id
                        sector_order[crag_id] = 0
                        crag_count += 1
                        logger.debug("Upserted crag '%s' → %s", crag_name, crag_id)

                    crag_id = crag_cache[crag_key]

                    # ----- Sector -----
                    sector_name = _blank_to_none(row.get("sector_name"))
                    sector_key = (crag_id, sector_name)

                    if sector_key not in sector_cache:
                        sector_id = uuid.uuid4()
                        idx = sector_order.get(crag_id, 0)
                        cur.execute(
                            _UPSERT_SECTOR,
                            (
                                str(sector_id),
                                str(crag_id),
                                sector_name,
                                _blank_to_none(row.get("sector_description")),
                                _blank_to_none(row.get("sector_approach_info")),
                                idx,
                            ),
                        )
                        returned = cur.fetchone()
                        sector_id = returned[0] if returned else sector_id
                        if isinstance(sector_id, str):
                            sector_id = uuid.UUID(sector_id)
                        sector_cache[sector_key] = sector_id
                        sector_order[crag_id] = idx + 1
                        route_order[sector_id] = 0
                        sector_count += 1
                        logger.debug(
                            "Upserted sector '%s' → %s", sector_name, sector_id
                        )

                    sector_id = sector_cache[sector_key]

                    # ----- Route -----
                    route_name = _blank_to_none(row.get("route_name"))
                    if not route_name:
                        # Sector-only row (no route) – skip route insert
                        continue

                    route_id = uuid.uuid4()
                    ridx = route_order.get(sector_id, 0)
                    cur.execute(
                        _UPSERT_ROUTE,
                        (
                            str(route_id),
                            str(sector_id),
                            route_name,
                            _blank_to_none(row.get("route_grade")),
                            _blank_to_none(row.get("route_grade_system")),
                            _blank_to_none(row.get("route_type")),
                            _to_float(row.get("route_height_m")),
                            _to_int(row.get("route_bolts")),
                            _blank_to_none(row.get("route_description")),
                            _blank_to_none(row.get("route_source_url")),
                            ridx,
                        ),
                    )
                    route_order[sector_id] = ridx + 1
                    route_count += 1

        logger.info(
            "Import complete: %d crags, %d sectors, %d routes",
            crag_count,
            sector_count,
            route_count,
        )

    finally:
        conn.close()

    return {"crags": crag_count, "sectors": sector_count, "routes": route_count}

