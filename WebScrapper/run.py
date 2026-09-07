#!/usr/bin/env python3
"""CLI entrypoint for climbmy-scraper.

Usage examples::

    # Scrape from theCrag and export to CSV
    python run.py --source thecrag --url https://www.thecrag.com/climbing/malaysia/batu-caves --state Selangor --out data/batu_caves.csv

    # Scrape from 27crags
    python run.py --source 27crags --url https://27crags.com/crags/batu-caves --out data/batu_caves_27.csv

    # Import a reviewed CSV into PostgreSQL
    python run.py --import-csv data/batu_caves.csv

    # Use shorthand flags
    python run.py -s thecrag -u https://www.thecrag.com/climbing/malaysia/batu-caves -o data/out.csv
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from adapters.base import BaseAdapter
from adapters.thecrag import TheCragAdapter
from adapters.twentysevencrags import TwentySevenCragsAdapter
from exporters.csv_exporter import export_csv
from importers.db_loader import load_csv_to_db

# ---------------------------------------------------------------------------
# Adapter registry
# ---------------------------------------------------------------------------

ADAPTERS: dict[str, type[BaseAdapter]] = {
    "thecrag": TheCragAdapter,
    "27crags": TwentySevenCragsAdapter,
}


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="climbmy-scraper",
        description="Scrape rock-climbing route data and export to CSV, or import CSV into PostgreSQL.",
    )

    # -- Import mode (standalone) --
    parser.add_argument(
        "--import-csv",
        metavar="PATH",
        default=None,
        help="Path to a reviewed CSV file to import into PostgreSQL. "
        "When set, --source/--url/--out are not required.",
    )

    # -- Scrape mode --
    parser.add_argument(
        "-s",
        "--source",
        choices=sorted(ADAPTERS.keys()),
        help="Source website to scrape from.",
    )
    parser.add_argument(
        "-u",
        "--url",
        help="URL of the crag page to scrape.",
    )
    parser.add_argument(
        "-o",
        "--out",
        help="Output CSV file path (e.g. data/batu_caves.csv).",
    )
    parser.add_argument(
        "--state",
        default=None,
        help="State / region name to tag the crag with (stored in crag_region).",
    )
    parser.add_argument(
        "--country",
        default=None,
        help="Country name to tag the crag with.",
    )

    # -- Shared --
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose (DEBUG) logging.",
    )
    return parser


# ---------------------------------------------------------------------------
# Sub-commands
# ---------------------------------------------------------------------------


def _run_scrape(args: argparse.Namespace) -> int:
    """Scrape a crag URL and export to CSV."""
    # Validate that scrape-mode args are present
    missing = []
    if not args.source:
        missing.append("--source / -s")
    if not args.url:
        missing.append("--url / -u")
    if not args.out:
        missing.append("--out / -o")
    if missing:
        print(
            f"Error: the following arguments are required for scrape mode: "
            f"{', '.join(missing)}",
            file=sys.stderr,
        )
        return 2

    adapter_cls = ADAPTERS[args.source]
    adapter = adapter_cls()

    logging.info("Scraping %s via %s …", args.url, adapter)

    try:
        crag = adapter.scrape(args.url)
    except Exception:
        logging.exception("Scraping failed")
        return 1

    # Override region / country if provided via CLI
    if args.state:
        crag.region = args.state
    if args.country:
        crag.country = args.country

    out_path = export_csv(crag, args.out)

    total_routes = sum(len(s.routes) for s in crag.sectors)
    print(
        f"\n[OK] Scraped {total_routes} routes across {len(crag.sectors)} sectors."
    )
    print(f"   CSV written to: {out_path.resolve()}\n")
    return 0


def _run_import(csv_path: str) -> int:
    """Import a reviewed CSV into PostgreSQL."""
    path = Path(csv_path)
    if not path.is_file():
        print(f"Error: CSV file not found: {path}", file=sys.stderr)
        return 1

    logging.info("Importing %s into PostgreSQL …", path)

    try:
        counts = load_csv_to_db(path)
    except Exception:
        logging.exception("Import failed")
        return 1

    print(
        f"\n[OK] Imported {counts['routes']} routes, "
        f"{counts['sectors']} sectors, "
        f"{counts['crags']} crags into PostgreSQL.\n"
    )
    return 0


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    # Configure logging
    level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
        datefmt="%H:%M:%S",
    )

    if args.import_csv:
        return _run_import(args.import_csv)

    return _run_scrape(args)


if __name__ == "__main__":
    sys.exit(main())
