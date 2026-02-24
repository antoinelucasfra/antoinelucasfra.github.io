"""
Shared utilities for sync_keep.py, backfill_descriptions.py and backfill_dates.py.
"""

from __future__ import annotations

import re
from pathlib import Path

import trafilatura

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

KNOWN_TYPES: frozenset[str] = frozenset(
    {
        "Blog",
        "Book",
        "Website",
        "Package",
        "Video",
        "Paper",
        "Course",
        "Community",
        "Newsletter",
        "Conference",
        "Forum",
        "Journal",
        "Repository",
    }
)

FIELD_ORDER = ("title", "type", "link", "language", "category", "description", "date")

DESC_MAX_LEN = 300

# Matches every auto-generated placeholder description pattern found in the file.
# A description that does NOT match this regex is treated as real and left alone.
_PLACEHOLDER_RE = re.compile(
    r"""^(
        A\ (blog|book|website|video|paper|course|community|resource|
             journal|newsletter|conference|tool|cheatsheet|code\ repository)
            \ (for|covering)
        |An\ (online\ course|R/Python\ package|R\ package|Python\ package|
               interactive|open-source)
        |Personal\ (website|blog)\ by
        |A\ code\ repository
    )""",
    re.VERBOSE | re.IGNORECASE,
)

# Matches ISO-8601 dates: YYYY-MM-DD, YYYY-MM, or YYYY
_DATE_RE = re.compile(r"^\d{4}(-\d{2}(-\d{2})?)?$")


# ---------------------------------------------------------------------------
# Description helpers
# ---------------------------------------------------------------------------


def is_placeholder(desc: str) -> bool:
    """Return True if *desc* looks like an auto-generated template."""
    return bool(_PLACEHOLDER_RE.match(desc.strip().strip('"')))


def fetch_description(url: str, downloaded: "bytes | str | None" = None) -> str:
    """
    Fetch *url* and extract a short human-readable description.

    If *downloaded* (the raw HTML already fetched for the page) is provided,
    it is reused instead of making a second HTTP request.

    Priority:
      1. og:description / meta description via trafilatura metadata
      2. First sentence of the extracted body text
      3. Empty string (caller decides what to do)
    """
    try:
        if downloaded is None:
            downloaded = trafilatura.fetch_url(url)
    except Exception:
        return ""

    if not downloaded:
        return ""

    # Priority 1 — page metadata (og:description, meta description)
    try:
        meta = trafilatura.extract_metadata(downloaded)
        if meta and meta.description:
            desc = meta.description.strip().replace("\n", " ")
            if len(desc) > 20:
                return desc[:DESC_MAX_LEN]
    except Exception:
        pass

    # Priority 2 — first sentence of body text
    try:
        text = trafilatura.extract(downloaded)
        if text:
            sentence = text.split(".")[0].strip().replace("\n", " ")
            if len(sentence) > 20:
                return (sentence + ".")[:DESC_MAX_LEN]
    except Exception:
        pass

    return ""


# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------


def fetch_date(url: str, downloaded: "bytes | str | None" = None) -> str:
    """
    Fetch *url* and extract its original publication date.

    Returns a string in YYYY-MM-DD, YYYY-MM, or YYYY format,
    or an empty string if no date could be found.

    If *downloaded* (the raw HTML bytes/str already fetched for the page)
    is provided, it is reused instead of making a second HTTP request —
    pass it when you already fetched the page to get the description.
    """
    try:
        if downloaded is None:
            downloaded = trafilatura.fetch_url(url)
    except Exception:
        return ""

    if not downloaded:
        return ""

    # Priority 1 — trafilatura metadata (date field)
    try:
        meta = trafilatura.extract_metadata(downloaded)
        if meta and meta.date:
            date_str = str(meta.date).strip()
            if _DATE_RE.match(date_str):
                return date_str
    except Exception:
        pass

    # Priority 2 — htmldate standalone (ships as a trafilatura dependency)
    try:
        import htmldate
        date_str = htmldate.find_date(downloaded, extensive_search=False)
        if date_str and _DATE_RE.match(date_str):
            return date_str
    except Exception:
        pass

    return ""


# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------


def parse_resources(path: Path) -> list[dict[str, str]]:
    """
    Parse *path* (resources.txt) into a list of dicts, one per entry.

    Each dict has the keys in FIELD_ORDER.  Fields missing from a block are
    stored as empty strings (backward-compatible: old blocks without 'date'
    will have date="").
    """
    raw = path.read_text(encoding="utf-8").splitlines()
    sep_idx = [i for i, line in enumerate(raw) if line.strip() == "---"]

    blocks: list[dict[str, str]] = []
    for k in range(0, len(sep_idx) - 1, 2):
        start = sep_idx[k] + 1
        end = sep_idx[k + 1]
        if start >= end:
            continue
        block_lines = raw[start:end]
        entry: dict[str, str] = {f: "" for f in FIELD_ORDER}
        entry["_raw_lines"] = block_lines  # type: ignore[assignment]
        for line in block_lines:
            if ":" not in line:
                continue
            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip().strip('"')
            if key in FIELD_ORDER:
                entry[key] = value
        blocks.append(entry)

    return blocks


def _format_block(entry: dict[str, str]) -> str:
    """Render one entry dict as a YAML block string (without trailing newline)."""
    lines = ["---"]
    for field in FIELD_ORDER:
        value = entry.get(field, "")
        # Escape any embedded double-quotes
        value = value.replace('"', '\\"')
        lines.append(f'{field}: "{value}"')
    lines.append("---")
    return "\n".join(lines)


def write_resources(path: Path, blocks: list[dict[str, str]]) -> None:
    """
    Write *blocks* back to *path* in the exact format of the original file:
    no blank lines between blocks, double-quoted values, fixed field order.
    """
    content = "\n".join(_format_block(b) for b in blocks) + "\n"
    path.write_text(content, encoding="utf-8")


def append_blocks(path: Path, new_blocks: list[dict[str, str]]) -> None:
    """Append *new_blocks* to the end of *path* without rewriting the whole file."""
    if not new_blocks:
        return
    chunk = "\n" + "\n".join(_format_block(b) for b in new_blocks) + "\n"
    with path.open("a", encoding="utf-8") as fh:
        fh.write(chunk)


def existing_links(path: Path) -> set[str]:
    """Return the set of all link values already in *path*."""
    return {b["link"] for b in parse_resources(path)}


# ---------------------------------------------------------------------------
# Block construction
# ---------------------------------------------------------------------------


def build_block(
    title: str,
    rtype: str,
    link: str,
    language: str,
    category: str,
    description: str,
    date: str = "",
) -> dict[str, str]:
    return {
        "title": title,
        "type": rtype,
        "link": link,
        "language": language,
        "category": category,
        "description": description,
        "date": date,
    }
