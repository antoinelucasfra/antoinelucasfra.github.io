# Antoine Lucas - Personal Website

Personal website and blog built with [Quarto](https://quarto.org/), with source content for the portfolio, blog, projects, CV, and the public resources catalog.

Live site: [antoinelucasfra.github.io](https://antoinelucasfra.github.io/)

Content license: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## Stack

- Quarto `1.9.37`
- R `4.5.2` with `renv.lock`
- Python `3.13` for helper tooling via `uv`

## Repository Layout

- `index.qmd`, `about.qmd`, `blog.qmd`, `projects.qmd`, `cv.qmd`: top-level site pages
- `posts/`: blog posts
- `projects/`: project case studies and the resources catalog
- `assets/`: shared stylesheets, images, and client-side scripts
- `_helpers/`: non-rendered helper code used during Quarto rendering
- `docs/`: generated site output for GitHub Pages
- `scripts/`: automation for catalog maintenance and the Google Keep sync workflow

The Quarto project now uses an explicit render allowlist in [_quarto.yml](_quarto.yml), so repository docs such as `TODO.md` and `CONTRIBUTING.md` are not published as website pages.

## Local Setup

### 1. Restore the R environment

From the repository root:

```sh
Rscript -e 'renv::restore()'
```

### 2. Restore the Python helper environments

The repository intentionally has two Python environments:

- root `pyproject.toml` for repo-level helper tooling
- `scripts/pyproject.toml` for the Google Keep sync and resource backfill automation

From the repository root:

```sh
uv sync
cd scripts
uv sync
```

Both environments are pinned to Python `3.13` via `.python-version` files.

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

- `.github/workflows/validate-site.yml`: renders the site on pull requests and checks that repo-only documents are not published
- `.github/workflows/publish.yml`: renders and deploys the site to GitHub Pages on pushes to `main`
- `.github/workflows/sync-keep.yml`: syncs catalog entries from Google Keep into `data/resources.txt`

## Notes

- `docs/` is generated output. Do not edit it manually.
- `data/resources.txt` is the source of truth for the resources catalog.
- `data/resources.csv` is derived data and should not be edited by hand.
