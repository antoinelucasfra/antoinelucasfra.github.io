# Antoine Lucas - Personal Website

Personal website and blog built with [Quarto](https://quarto.org/), with source content for the portfolio, blog, projects, CV, and the public resources catalog.

Live site: [antoinelucasfra.github.io](https://antoinelucasfra.github.io/)

Content license: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## Stack

- Quarto `1.9.37`
- R `4.5.2` with `rv.lock` (managed by [`rv`](https://github.com/A2-ai/rv))
- Python `3.13` for helper tooling via `uv` (single environment in `scripts/`)

## Repository Layout

- `index.qmd`, `about.qmd`, `blog.qmd`, `projects.qmd`, `cv.qmd`: top-level site pages
- `posts/`: blog posts
- `projects/`: project case studies and the resources catalog
- `assets/`: shared stylesheets, images, and client-side scripts
- `_helpers/`: non-rendered helper code used during Quarto rendering
- `docs/`: local Quarto render output used by CI for GitHub Pages deployment, not committed
- `scripts/`: automation for catalog maintenance and the Google Keep sync workflow

The Quarto project now uses an explicit render allowlist in [_quarto.yml](_quarto.yml), so repository docs such as `TODO.md` and `CONTRIBUTING.md` are not published as website pages.

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
quarto render cv-typst.qmd
```

Backfill resource metadata locally:

```sh
cd scripts
uv run python backfill.py --mode both
```

## Automation

- `.github/workflows/site.yml`: renders the site on pull requests (checks that repo-only documents are not published) and deploys to GitHub Pages on pushes to `main`
- `.github/workflows/sync-keep.yml`: syncs catalog entries from Google Keep into `data/resources.txt`

## Notes

- `docs/` is generated output. Do not edit or commit it manually.
- `data/resources.txt` is the source of truth for the resources catalog.
- `scripts/make_covers.py` regenerates the post cover SVGs in `assets/images/covers/`.
