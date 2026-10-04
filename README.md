# Antoine Lucas - Personal Website

Personal website and blog built with [Quarto](https://quarto.org/), with source content for the portfolio, blog, projects, CV, and the public resources catalog.

Live site: [antoinelucasfra.github.io](https://antoinelucasfra.github.io/)

Content license: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## Stack

- Quarto `1.9.37`
- R `4.5.2` with `rv.lock` (managed by [`rv`](https://github.com/A2-ai/rv))
- Python `3.13` for helper tooling via `uv` (single environment in `scripts/`)

## Repository Layout

- `index.qmd`, `about.qmd`, `blog.qmd`, `projects.qmd`: top-level site pages
- `cv/`: CV pages (`index`, `ai`, `biostat`) and the two Typst PDFs, plus the shared `profile.yml`, the renderer and the Typst partials
- `catalog/`: the resources catalog — page, `resources.txt` source, listing engine and card template
- `posts/`: blog posts
- `projects/`: project case studies
- `topics/`: topic landing pages
- `assets/`: images, post cover art, and the favicon
- `_helpers/`: non-rendered R helpers sourced by the pages (`profile.R`, `links.R`, `site-render.R`)
- `scripts/`: Python tooling in a single `uv` environment (Keep sync, metadata backfill, cover generation)
- `rv/`, `rproject.toml`, `rv.lock`: the R environment, managed by [`rv`](https://github.com/A2-ai/rv)
- `docs/`: local Quarto render output used by CI for GitHub Pages deployment, not committed

The Quarto project now uses an explicit render allowlist in [_quarto.yml](_quarto.yml), so repository docs such as `CONTRIBUTING.md` are not published as website pages.

## Local Setup

### 1. Restore the R environment

From the repository root:

```sh
rv sync
```

### 2. Restore the Python helper environment

All Python tooling lives in `scripts/`:

```sh
cd scripts
uv sync
```

The environment is pinned to Python `3.13` via `scripts/.python-version`.

## Common Commands

Preview the website locally:

```sh
quarto preview
```

Render the full site:

```sh
quarto render
```

Render the PDF CV only:

```sh
quarto render cv/typst-ai.qmd
```

Backfill resource metadata locally:

```sh
cd scripts
uv run python backfill.py --mode both
```

## Automation

- `.github/workflows/site.yml`: renders the site on pull requests (checks that repo-only documents are not published) and deploys to GitHub Pages on pushes to `main`

## Notes

- `docs/` is generated output. Do not edit or commit it manually.
- `data/resources.txt` is the source of truth for the resources catalog.
- `scripts/make_covers.py` regenerates the post cover SVGs in `assets/images/covers/`.
