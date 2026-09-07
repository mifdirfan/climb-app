"""Abstract base adapter that every scraping source must implement."""

from __future__ import annotations

from abc import ABC, abstractmethod

from models import CragData


class BaseAdapter(ABC):
    """Interface for a site-specific scraping adapter.

    Each concrete adapter (theCrag, 27crags, etc.) must subclass this and
    implement :meth:`scrape`.
    """

    @abstractmethod
    def scrape(self, url: str) -> CragData:
        """Scrape the given URL and return a fully-populated CragData model.

        Parameters
        ----------
        url:
            The crag page URL on the source website.

        Returns
        -------
        CragData
            Nested model containing sectors and routes.
        """
        ...

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}>"

