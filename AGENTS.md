# AGENTS.md — Antoines Personal Quarto Site

## Project Overview

Personal website and blog at [antoinelucasfra.github.io](https://antoinelucasfra.github.io/), built with Quarto >= 1.9.37. Content focuses on R/Shiny product engineering, statistical computing, ML systems in regulated environments, reproducibility, and dev tooling.

**Content license:** CC BY-NC-SA 4.0.

## Architecture & Data Flow

```
_quarto.yml                    # Project config: pages, theme, navbar, listing
_extensions/antoinelucasfra/al-brand/  # AL Brand extension (canonical): brand.yml + SCSS suite
assets/stylesheets/            # Thin theme wrappers (al-brand-light/dark.scss) + resources-catalog.css
_helpers/                      # R helper scripts sourced during render
_extensions/                   # Quarto extensions (iconify, fontawesome, custom-callout, highlight-text)
data/                          # Source data: profile.yml, resources.txt, resources.csv
scripts/                       # Python automation (backfill, sync_keep)
posts/                         # Blog post source (each subdir has index.qmd)
projects/                      # Project pages: .qmd files
docs/                          # Rendered output (quarto render -> docs/) - not committed
```

Rendering flow: `quarto render` reads `.qmd` files, processes R/Python code chunks (with `freeze: auto` caching), applies the brand/SCSS theme, and outputs to `docs/`. The index page (`index.qmd`) sources `_helpers/profile_render.R` to build a dynamic hero/profile section from `data/profile.yml`.

**Key nuance — two Python environments:**
- Root `pyproject.toml` for repo-level helper tooling (dep: `trafilatura`)
- `scripts/pyproject.toml` for Google Keep sync + resource backfill automation (deps: `gkeepapi`, `gpsoauth`, `trafilatura`)

## Key Directories

| Directory | Purpose |
|-----------|---------|
 | `posts/` | Blog posts, each in a subdirectory with `index.qmd` |
 | `projects/` | Project case study pages (single `.qmd` files) |
 | `topics/` | Topic-filtered blog listings (`index.qmd` hub + `r-shiny.qmd`, `reproducibility.qmd`, `python-ml.qmd`) |
 | `_extensions/` | Quarto extension: `custom-callout` (removed — replaced with native Quarto callouts) |
 | `_helpers/` | R helper code sourced during Quarto rendering (`profile_render.R`, `resources_catalog.R`, `topic_listing.R`) |
| `assets/stylesheets/` | Thin wrappers importing the al-brand extension (`al-brand-light.scss`, `al-brand-dark.scss`) and `resources-catalog.css` |
| `assets/images/` | Profile picture, blog placeholder SVG |
| `assets/scripts/` | Client-side JS (`resources-catalog.js`) |
| `data/` | `profile.yml`, `resources.txt` (source of truth for catalog), `resources.csv` (derived) |
| `scripts/` | Python automation: `backfill.py`, `sync_keep.py`, `utils.py` |
| `docs/` | Quarto HTML output — do not edit manually |

## Development Commands

### Preview / Render

```bash
quarto preview              # Live preview with hot-reload
quarto render               # Full site render to docs/
quarto render cv-typst.qmd  # Render PDF CV only
```

### R Environment

```bash
Rscript -e 'renv::restore()'    # Install R dependencies from renv.lock
Rscript -e 'devtools::load_all()'  # Not applicable — not an R package
```

### Python Environment (root)

```bash
uv sync                                      # Sync root Python helpers
uv run python scripts/backfill.py --mode both  # Run resource backfill
```

### Python Environment (scripts/ — Google Keep sync)

```bash
cd scripts && uv sync                        # Sync sync_keep dependencies
uv run python sync_keep.py                   # Sync catalog from Google Keep
```

### Formatting

```bash
air format .    # R formatting (line-width 100, configured in air.toml)
```

### CI Workflows

`.github/workflows/` contains:
- `validate-site.yml` — renders site on PRs, checks repo-only docs not published
- `publish.yml` — renders + deploys to GitHub Pages on pushes to main
- `sync-keep.yml` — scheduled sync of Google Keep -> `data/resources.txt`

## Code Conventions & Common Patterns

- **Quarto pages** use YAML frontmatter with `title`, `description`, `format` overrides where needed.
- **Blog posts** use native Quarto callouts (`callout-warning`, `callout-important`, `callout-tip`) instead of the custom-callout extension.
- **Profile rendering**: `index.qmd` sources `_helpers/profile_render.R` which reads `data/profile.yml` and builds an HTML hero section using `htmltools`.
- **Resources catalog**: `projects/resources_catalog.qmd` sources `_helpers/resources_catalog.R`, reads `data/resources.txt`.
- **R code** in `.qmd` files uses `here::here()` for paths, `yaml::read_yaml()` for YAML data.
- **No global R package** — helpers are ad-hoc scripts, not a formal R package.
- **Air config**: `air.toml` sets line-width 100.
- **No Python linting config** found — `ruff` not configured for this repo specifically, but workspace convention uses `ruff`.

## Important Files

| File | Purpose |
|------|---------|
| `_quarto.yml` | Site configuration: pages, output dir, theme, navbar, listing, extensions |
| `_extensions/antoinelucasfra/al-brand/brand.yml` | Full brand identity: colors (void/sky/teal palette), fonts (Space Grotesk, DM Sans, JetBrains Mono), semantic roles, defaults. Publishable copy in `quarto-al-brand/` — sync with `scripts/sync_extension.sh` |
| `index.qmd` | Homepage with dynamic profile hero section |
| `blog.qmd` | Blog listing with grid layout, pagination, categories, RSS feed |
| `projects.qmd` | Projects listing page |
| `cv.qmd` / `cv-typst.qmd` | HTML and PDF/typst CV versions |
| `data/profile.yml` | Profile data driving the homepage hero |
| `data/resources.txt` | Source of truth for the resources catalog |
| `_helpers/profile_render.R` | R code that builds the homepage hero from `profile.yml` |
| `_helpers/resources_catalog.R` | R code that builds the resources catalog page |
| `scripts/backfill.py` | Backfill resource metadata |
| `scripts/sync_keep.py` | Google Keep -> resources.txt sync |
| `TODO.md` | Ongoing tasks and completed items |
| `air.toml` | R formatting config (line-width 100) |

## Runtime / Tooling Preferences

- **R**: `renv::restore()` to install dependencies. `air` for formatting.
- **Python**: `uv` exclusively. Never `pip`. Two environments (root + `scripts/`), both pinned to Python 3.13 via `.python-version`.
- **Quarto**: Version pinned to `>=1.9.37` in `_quarto.yml`. Freeze auto-enabled — cached computations in `_freeze/`.
- **Git**: Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`, `render:`). Feature branches from main, PRs to main. Never push to main directly.
- **CI**: GitHub Actions (validate on PR, deploy on main push, scheduled Keep sync).

## Testing & QA

- **No formal test suite** exists for this project — it is a Quarto website, not a software package.
- **Validation**: PR CI renders the full site and checks no repo-only docs leak into output.
- **Manual check**: Run `quarto render` and visually inspect or use `git diff` on `docs/` to verify rendering changes.
- **Formatting**: `air format .` for R files.
- **No Python linting** configured in this repo — workspace convention would use `ruff check . && ruff format .`.
