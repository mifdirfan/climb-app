"""Flatten nested CragData → SectorData → RouteData into a single CSV file."""

from __future__ import annotations

import csv
from pathlib import Path

from models import CragData

# Column order for the exported CSV.
CSV_COLUMNS: list[str] = [
    "crag_name",
    "crag_country",
    "crag_region",
    "crag_latitude",
    "crag_longitude",
    "crag_source",
    "crag_source_url",
    "sector_name",
    "sector_description",
    "sector_approach_info",
    "route_name",
    "route_grade",
    "route_grade_system",
    "route_type",
    "route_height_m",
    "route_bolts",
    "route_description",
    "route_source_url",
]


def flatten_crag(crag: CragData) -> list[dict[str, str | float | int | None]]:
    """Convert a nested CragData model into a list of flat row dicts.

    Each row represents one route, with crag and sector fields denormalised
    so every row is self-contained and easy to review in a spreadsheet.

    If a sector has no routes an entry is still emitted (route fields will be
    ``None``) so that the sector itself is not lost.
    """
    rows: list[dict[str, str | float | int | None]] = []

    crag_fields = {
        "crag_name": crag.name,
        "crag_country": crag.country,
        "crag_region": crag.region,
        "crag_latitude": crag.latitude,
        "crag_longitude": crag.longitude,
        "crag_source": crag.source,
        "crag_source_url": crag.source_url,
    }

    for sector in crag.sectors:
        sector_fields = {
            "sector_name": sector.name,
            "sector_description": sector.description,
            "sector_approach_info": sector.approach_info,
        }

        if not sector.routes:
            # Keep the sector even when it has no routes yet.
            rows.append({**crag_fields, **sector_fields})
            continue

        for route in sector.routes:
            route_fields = {
                "route_name": route.name,
                "route_grade": route.grade,
                "route_grade_system": route.grade_system,
                "route_type": route.route_type,
                "route_height_m": route.height_m,
                "route_bolts": route.bolts,
                "route_description": route.description,
                "route_source_url": route.source_url,
            }
            rows.append({**crag_fields, **sector_fields, **route_fields})

    return rows


def export_csv(crag: CragData, output_path: str | Path) -> Path:
    """Write a CragData model to a flat CSV file.

    Parameters
    ----------
    crag:
        The scraped crag data to export.
    output_path:
        Destination file path (will be created / overwritten).

    Returns
    -------
    Path
        The resolved path to the written CSV file.
    """
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    rows = flatten_crag(crag)

    with output_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)

    return output_path

