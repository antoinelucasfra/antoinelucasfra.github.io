"""
backfill_dates.py — one-shot local script.

Reads data/resources.txt, finds every entry that has no date yet, fetches
the original publication date of each URL via trafilatura / htmldate, and
writes it back to the file.

Run from the repo root:

    cd scripts/
    uv sync
    RESOURCES_PATH=../data/resources.txt uv run python backfill_dates.py

Or pass the path as a CLI argument:

    uv run python backfill_dates.py ../data/resources.txt

Options
-------
--force     Re-fetch dates for ALL entries, even those that already have one.
--dry-run   Print what would be changed without writing anything.
--limit N   Stop after fetching N URLs (useful for testing).
"""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path

import trafilatura

from utils import (
    fetch_date,
    fetch_description,
    parse_resources,
    write_resources,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _resolve_path() -> Path:
    # Strip option flags from argv to find the optional positional path argument
    positional = [a for a in sys.argv[1:] if not a.startswith("-") and not a.isdigit()]
    if positional:
        p = Path(positional[0])
    else:
        env = os.environ.get("RESOURCES_PATH")
        if env:
            p = Path(env)
        else:
            # Default: script lives in scripts/, resources.txt is one level up
            p = Path(__file__).parent.parent / "data" / "resources.txt"
    if not p.exists():
        print(f"ERROR: resources file not found: {p}", file=sys.stderr)
        sys.exit(1)
    return p.resolve()


def _parse_flags() -> tuple[bool, bool, int | None]:
    """Return (force, dry_run, limit)."""
    args = sys.argv[1:]
    force = "--force" in args
    dry_run = "--dry-run" in args
    limit: int | None = None
    for i, a in enumerate(args):
        if a == "--limit" and i + 1 < len(args):
            try:
                limit = int(args[i + 1])
            except ValueError:
                pass
    return force, dry_run, limit


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    force, dry_run, limit = _parse_flags()
    resources_path = _resolve_path()

    if dry_run:
        print("DRY RUN — no changes will be written.\n")

    print(f"Reading {resources_path} ...")
    blocks = parse_resources(resources_path)
    total = len(blocks)

    if force:
        to_update = blocks
        print(f"  {total} entries total — --force: re-fetching all dates\n")
    else:
        to_update = [b for b in blocks if not b.get("date", "").strip()]
        already_done = total - len(to_update)
        print(f"  {total} entries total")
        print(f"  {already_done} already have a date (skipped)")
        print(f"  {len(to_update)} entries without a date\n")

    if not to_update:
        print("Nothing to do.")
        return

    if limit is not None:
        to_update = to_update[:limit]
        print(f"  --limit {limit}: fetching only the first {limit} entries\n")

    updated = 0
    failed = 0
    fetched = 0

    for i, block in enumerate(to_update, start=1):
        url = block["link"]
        prefix = f"[{i:>4}/{len(to_update)}]"

        # Fetch the page once and reuse it for both date and (if needed) description
        try:
            downloaded = trafilatura.fetch_url(url)
        except Exception:
            downloaded = None

        fetched += 1

        # Extract date
        date_str = fetch_date(url, downloaded=downloaded)

        if date_str:
            block["date"] = date_str
            updated += 1
            print(f"{prefix} OK    {url}")
            print(f"         -> date: {date_str}")
        else:
            # Leave as empty string — no invented date
            block["date"] = ""
            failed += 1
            print(f"{prefix} SKIP  {url} (no date found)")

        # Polite delay — avoid hammering servers
        time.sleep(0.3)

    print(f"\nFetched {fetched} URLs — {updated} dates found, {failed} not found.")

    if dry_run:
        print("\nDRY RUN — nothing written.")
    else:
        print(f"\nWriting {resources_path} ...")
        write_resources(resources_path, blocks)
        print("\n--- Summary ---")
        print(f"  Updated : {updated}")
        print(f"  Not found : {failed} (date left as empty string)")
        if limit is None:
            print(f"  Skipped : {total - len(to_update)} (already had a date)")
        print("\nReview changes with:")
        print("  git diff data/resources.txt")


if __name__ == "__main__":
    main()
