#!/usr/bin/env python3
"""Generate branded SVG cover images for each blog post.

Reads title/categories from posts/*/index.qmd frontmatter and writes
assets/images/covers/<slug>.svg. Deterministic; re-run anytime.
"""

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images" / "covers"

# accent gradient pairs (start, end)
ACCENTS = [
    ("#0284C7", "#38BDF8"),
    ("#0369A1", "#7DD3FC"),
    ("#0EA5E9", "#38BDF8"),
    ("#075985", "#0EA5E9"),
]

FONT_HEAD = "Space Grotesk, Arial, sans-serif"
FONT_MONO = "JetBrains Mono, monospace"


def parse_fm(text: str) -> dict:
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        kv = re.match(r'^(title|description):\s*"?(.*?)"?\s*$', line)
        if kv:
            fm[kv.group(1)] = kv.group(2).strip('"')
        cats = re.match(r"^categories:\s*\[(.*)\]", line)
        if cats:
            fm["categories"] = [c.strip() for c in cats.group(1).split(",")]
    return fm


def wrap(title: str, first=26, mid=34, last=30, max_lines=3):
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


def make_svg(title: str, cats: list[str], slug: str) -> str:
    h = int(hashlib.sha256(slug.encode()).hexdigest(), 16)
    c1, c2 = ACCENTS[h % len(ACCENTS)]
    cx = 1150 + (h >> 8) % 250
    cy = 200 + (h >> 16) % 150

    tag_y = 170
    tags = []
    tx = 120
    for cat in cats[:2]:
        w = 46 + 22 * len(cat)
        tags.append(
            f'<rect x="{tx}" y="{tag_y - 40}" width="{w}" height="56" rx="28" fill="{c2}" opacity="0.14"/>'
            f'<text x="{tx + w / 2}" y="{tag_y}" fill="{c2}" font-family="{FONT_MONO}" '
            f'font-size="28" font-weight="600" text-anchor="middle">{cat.upper()}</text>'
        )
        tx += w + 24

    lines = wrap(title.upper())
    max_len = max(len(line) for line in lines)
    size = 88 if max_len <= 24 else 74
    lh = int(size * 1.12)
    y0 = 480 - (len(lines) - 1) * lh // 2

    title_el = "".join(
        f'<text x="120" y="{y0 + i * lh}" fill="#E6EDF3" font-family="{FONT_HEAD}" '
        f'font-size="{size}" font-weight="700">{line}</text>'
        for i, line in enumerate(lines)
    )

    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 900" role="img" aria-label="Cover for {title}">
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
  <rect width="1600" height="900" fill="url(#bg)"/>
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


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for post in sorted((ROOT / "posts").glob("*/index.qmd")):
        text = post.read_text()
        if "draft: true" in text:
            continue
        fm = parse_fm(text)
        if not fm.get("title"):
            print(f"skip (no title): {post}", file=sys.stderr)
            continue
        slug = post.parent.name
        svg = make_svg(fm["title"], fm.get("categories", []), slug)
        (OUT / f"{slug}.svg").write_text(svg)
        n += 1
    print(f"wrote {n} covers to {OUT}")


if __name__ == "__main__":
    main()
