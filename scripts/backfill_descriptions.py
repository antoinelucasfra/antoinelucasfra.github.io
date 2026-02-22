"""
backfill_descriptions.py — one-shot local script.

Reads data/resources.txt, finds every entry whose description is an
auto-generated placeholder, fetches the real page via trafilatura, and
overwrites the placeholder with an actual description.

Run from the repo root:

    cd scripts/
    uv sync
    RESOURCES_PATH=../data/resources.txt uv run python backfill_descriptions.py

Or pass the path as a CLI argument:

    uv run python backfill_descriptions.py ../data/resources.txt
"""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path

from utils import (
    fetch_description,
    is_placeholder,
    parse_resources,
    write_resources,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _resolve_path() -> Path:
    if len(sys.argv) > 1:
        p = Path(sys.argv[1])
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


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    resources_path = _resolve_path()

    print(f"Reading {resources_path} ...")
    blocks = parse_resources(resources_path)
    total = len(blocks)

    to_update = [b for b in blocks if is_placeholder(b["description"])]
    already_real = total - len(to_update)

    print(f"  {total} entries total")
    print(f"  {already_real} already have real descriptions (skipped)")
    print(f"  {len(to_update)} placeholders to replace\n")

    if not to_update:
        print("Nothing to do.")
        return

    updated = 0
    failed = 0

    for i, block in enumerate(to_update, start=1):
        url = block["link"]
        prefix = f"[{i:>4}/{len(to_update)}]"

        new_desc = fetch_description(url)

        if new_desc:
            block["description"] = new_desc
            updated += 1
            print(f"{prefix} OK    {url}")
            print(f"         -> {new_desc[:80]}{'...' if len(new_desc) > 80 else ''}")
        else:
            # Leave as empty string — do not re-insert a template
            block["description"] = ""
            failed += 1
            print(f"{prefix} SKIP  {url} (no content extracted)")

        # Polite delay — avoid hammering servers
        time.sleep(0.5)

    print(f"\nWriting {resources_path} ...")
    write_resources(resources_path, blocks)

    print("\n--- Summary ---")
    print(f"  Updated : {updated}")
    print(f"  Failed  : {failed} (description set to empty)")
    print(f"  Skipped : {already_real} (already real)")
    print("\nReview changes with:")
    print("  git diff data/resources.txt")


if __name__ == "__main__":
    main()
