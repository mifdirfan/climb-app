# Project: climbmy-scraper

## Goal
A standalone Python-based scraping and ingestion pipeline for rock climbing data.

## Workflow: Two-Step Staging
1. Extract crag, sector, and route data from source websites (theCrag, 27crags) and export to a flat, human-reviewable CSV file.
2. An ingestion script reads the verified CSV file and inserts relational rows into local PostgreSQL / Supabase.

## Architecture
- `models.py`: Pydantic schemas (CragData, SectorData, RouteData).
- `adapters/`: Adapter pattern implementations (`base.py`, `thecrag.py`, `twentysevencrags.py`).
- `exporters/csv_exporter.py`: Flatten nested models and write to `.csv`.
- `importers/db_loader.py`: Read `.csv` and insert into Postgres using `psycopg2`.
- `run.py`: CLI entrypoint with `--source`, `--url`, `--state`, `--export-csv`, and `--import-csv` flags.