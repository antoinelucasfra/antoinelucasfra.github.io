#!/usr/bin/env python3
"""Generate branded SVG cover images for each blog post.

Reads title/categories from posts/*/index.qmd frontmatter and writes
assets/images/covers/<slug>.svg. Deterministic; re-run anytime.

`--check` verifies that the committed covers match what the current generator
produces and exits non-zero when they do not. CI runs it, so a post title can no
longer change without its cover following.

Two constraints shape the type setting:

* The listing embeds these files as `<img src="...svg">`. An SVG referenced that
  way renders in isolation: the fonts the page loads do not reach it, so the
  `font-family` below resolves against whatever the reader has installed.
  Space Grotesk is narrower than Arial, so titles are sized for the Arial
  fallback and a viewer that does have Space Grotesk can only render smaller.
* Listing cards crop with `object-fit: cover`, so lines are budgeted to leave a
  right margin rather than running to the canvas edge.

The palette hash and the size ladder are deliberately stable: change either one
and every committed cover is reshuffled.
"""

import argparse
import hashlib
import html
import re
import sys
from collections.abc import Iterator
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images" / "covers"

# accent gradient pairs (start, end)
ACCENTS = [
    ("#0284C7", "#38BDF8"),
    ("#0369A1", "#7DD3FC"),
    ("#0EA5E9", "#38BDF8"),
    ("#075985", "#0EA5E9"),
]

# Canvas is 1600x900 with text starting at x=120. The budget leaves a 60 px right
# margin for the crop applied by listing cards.
CANVAS_W = 1600
TEXT_X = 120
WIDTH_BUDGET = 1420

# Arial Bold uppercase averages roughly 0.69 em per character; 0.70 keeps a
# little headroom for wide titles such as those full of M and W.
CHAR_EM = 0.70

# Discrete sizes keep the blog grid visually consistent. 88 and 74 are the two
# tiers this site has always used; 66 is the smallest rung any current title
# needs. The largest size whose widest line fits the budget wins.
SIZE_LADDER = (88, 74, 66, 58)

# Characters per line, first/middle/last.
WRAP = (24, 30, 28)
MAX_LINES = 3

FONT_HEAD = "Space Grotesk, Arial, sans-serif"
FONT_MONO = "JetBrains Mono, monospace"


def parse_fm(text: str) -> dict:
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return {}
    return yaml.safe_load(m.group(1)) or {}


def wrap(title: str, first=WRAP[0], mid=WRAP[1], last=WRAP[2], max_lines=MAX_LINES):
    words, lines, cur = title.split(), [], ""
    for w in words:
        limit = [first, mid, last][min(len(lines), 2)]
        if cur and len(cur) + 1 + len(w) > limit:
            lines.append(cur)
            cur = w
        else:
            cur = f"{cur} {w}".strip()
    if cur:
        lines.append(cur)
    if len(lines) > max_lines:
        lines = lines[:max_lines]
        lines[-1] = lines[-1][: last - 1].rstrip() + "…"
    return lines


def title_size(max_len: int) -> int:
    """Largest ladder size whose widest line fits the width budget."""
    for size in SIZE_LADDER:
        if max_len * CHAR_EM * size <= WIDTH_BUDGET:
            return size
    return SIZE_LADDER[-1]


def palette(slug: str) -> tuple[str, str, int, int]:
    """Accent pair and circle position for a slug.

    md5 is a cheap deterministic shuffle here, not a security primitive, and
    `usedforsecurity=False` says so. Swapping in a different hash moves the
    accent and the circle of every committed cover, which is why this stays put.
    """
    h = int(hashlib.md5(slug.encode(), usedforsecurity=False).hexdigest(), 16)
    c1, c2 = ACCENTS[h % len(ACCENTS)]
    cx = 1150 + (h >> 8) % 250
    cy = 200 + (h >> 16) % 150
    return c1, c2, cx, cy


def make_svg(title: str, cats: list[str], slug: str) -> str:
    c1, c2, cx, cy = palette(slug)
    c1, c2, cx, cy = palette(slug)

    tag_y = 170
    tags = []
    tx = TEXT_X
    for cat in cats[:2]:
        w = 46 + 22 * len(cat)
        tags.append(
            f'<rect x="{tx}" y="{tag_y - 40}" width="{w}" height="56" rx="28" fill="{c2}" opacity="0.14"/>'
            f'<text x="{tx + w / 2}" y="{tag_y}" fill="{c2}" font-family="{FONT_MONO}" '
            f'font-size="28" font-weight="600" text-anchor="middle">{html.escape(cat.upper())}</text>'
        )
        tx += w + 24

    lines = wrap(title.upper())
    size = title_size(max(len(line) for line in lines))
    lh = int(size * 1.12)
    y0 = 480 - (len(lines) - 1) * lh // 2

    title_el = "".join(
        f'<text x="{TEXT_X}" y="{y0 + i * lh}" fill="#E6EDF3" font-family="{FONT_HEAD}" '
        f'font-size="{size}" font-weight="700">{html.escape(line)}</text>'
        for i, line in enumerate(lines)
    )

    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS_W} 900" role="img" aria-label="Cover for {html.escape(title)}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0F1117"/>
      <stop offset="100%" stop-color="#161B22"/>
    </linearGradient>
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="{c1}"/>
      <stop offset="100%" stop-color="{c2}"/>
    </linearGradient>
  </defs>
  <rect width="{CANVAS_W}" height="900" fill="url(#bg)"/>
  <g opacity="0.18" stroke="#30363D" stroke-width="1">
    <path d="M0 225H1600"/><path d="M0 450H1600"/><path d="M0 675H1600"/>
    <path d="M400 0V900"/><path d="M800 0V900"/><path d="M1200 0V900"/>
  </g>
  <circle cx="{cx}" cy="{cy}" r="240" fill="{c1}" opacity="0.13"/>
  <circle cx="{cx + 90}" cy="{cy + 40}" r="130" fill="{c2}" opacity="0.10"/>
  {"".join(tags)}
  {title_el}
  <rect x="120" y="640" width="220" height="14" rx="7" fill="url(#accent)"/>
  <text x="120" y="720" fill="#57606A" font-family="{FONT_MONO}" font-size="30">Antoine Lucas — field notes</text>
</svg>'''


def generate() -> Iterator[tuple[str, str]]:
    """Yield (slug, svg) for every published post, in a stable order."""
    for post in sorted((ROOT / "posts").glob("*/index.qmd")):
        text = post.read_text(encoding="utf-8")
        fm = parse_fm(text)
        # Parse the frontmatter rather than substring-searching the file: a post
        # quoting `draft: true` in its body must not be mistaken for a draft.
        if fm.get("draft") is True:
            print(f"skip (draft): {post}", file=sys.stderr)
            continue
        if not fm.get("title"):
            print(f"skip (no title): {post}", file=sys.stderr)
            continue
        slug = post.parent.name
        yield slug, make_svg(fm["title"], fm.get("categories", []), slug)


def stale() -> list[str]:
    """Slugs whose committed cover differs from a freshly generated one.

    Reads bytes and tolerates undecodable ones: covers written before this
    script wrote UTF-8 explicitly were encoded with the platform default, so a
    legacy file counts as stale rather than crashing the check. Line endings are
    normalised because a Windows checkout rewrites them.
    """
    out = []
    for slug, svg in generate():
        path = OUT / f"{slug}.svg"
        raw = path.read_bytes() if path.exists() else b""
        current = raw.decode("utf-8", errors="surrogateescape").replace("\r\n", "\n")
        if current != svg:
            out.append(slug)
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="report covers that are out of date instead of writing them",
    )
    args = parser.parse_args(argv)

    if args.check:
        out_of_date = stale()
        for slug in out_of_date:
            print(f"stale cover: {slug}", file=sys.stderr)
        if out_of_date:
            print(
                f"{len(out_of_date)} cover(s) out of date; run make_covers.py",
                file=sys.stderr,
            )
            return 1
        print("all covers current")
        return 0

    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for slug, svg in generate():
        (OUT / f"{slug}.svg").write_text(svg, encoding="utf-8", newline="\n")
        n += 1
    print(f"wrote {n} covers to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
