"""Pydantic schemas for rock-climbing domain objects."""

from __future__ import annotations

from pydantic import BaseModel, Field


class RouteData(BaseModel):
    """A single climbing route within a sector."""

    name: str
    grade: str | None = None
    grade_system: str | None = Field(
        default=None, description="Grading system, e.g. 'french', 'yds', 'font'"
    )
    route_type: str | None = Field(
        default=None, description="e.g. 'sport', 'trad', 'boulder'"
    )
    height_m: float | None = Field(default=None, description="Route height in metres")
    bolts: int | None = None
    description: str | None = None
    source_url: str | None = None


class SectorData(BaseModel):
    """A sector (wall / area) that contains routes."""

    name: str
    description: str | None = None
    approach_info: str | None = None
    routes: list[RouteData] = Field(default_factory=list)


class CragData(BaseModel):
    """Top-level crag containing one or more sectors."""

    name: str
    country: str | None = None
    region: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    description: str | None = None
    source: str | None = Field(
        default=None, description="Source website identifier, e.g. 'thecrag'"
    )
    source_url: str | None = None
    sectors: list[SectorData] = Field(default_factory=list)

