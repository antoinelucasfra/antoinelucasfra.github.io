# Antoine Lucas - Personal Website

Personal website and blog built with [Quarto](https://quarto.org/), with source content for the portfolio, blog, projects, CV, and the public resources catalog.

Live site: [antoinelucasfra.github.io](https://antoinelucasfra.github.io/)

Content license: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## Stack

- Quarto `1.9.37` pinned in CI (`_quarto.yml` requires `>=1.9.37`)
- R `4.5.2` with `rv.lock` (managed by [`rv`](https://github.com/A2-ai/rv))
- Python `3.13` for helper tooling via `uv` (single environment in `scripts/`)

## Repository Layout

- `cv/`: CV pages (`index`, `ai`, `biostat`) written as plain Quarto markdown; each CV renders to HTML and to a Typst PDF (`cv.pdf`, `cv-biostat.pdf`) from the same source. `_header.inc.qmd`, `_education.inc.qmd` and `_certs-languages.inc.qmd` hold the blocks both CVs share; `profile.yml` holds the homepage and About data, `icons/` the PDF contact icons
- `_extensions/awesomecv/`: vendored [`quarto-awesomecv-typst`](https://github.com/kazuyanagimoto/quarto-awesomecv-typst) layout for the CV PDFs
- `catalog/`: the resources catalog page, the `resources.txt` source, the listing engine and the card template
- `posts/`, `projects/`, `topics/`: blog posts, project case studies, topic landing pages
- `_helpers/`: non-rendered R helpers sourced by the pages (`profile.R`, `links.R`, `site-render.R`)
- `scripts/`: Python tooling in a single `uv` environment (Keep sync, metadata backfill, cover generation)
- `rv/`, `rproject.toml`, `rv.lock`: the R environment, managed by [`rv`](https://github.com/A2-ai/rv)
- `docs/`: render output, ignored by git; CI uploads it to GitHub Pages
- `_freeze/`: Quarto freeze cache, committed for `posts/` and `site_libs/` only

`_quarto.yml` holds an explicit render allowlist, so repository docs such as `CONTRIBUTING.md` are not published.

## Local Setup

### 1. Restore the R environment

Install [`rv`](https://github.com/A2-ai/rv) from its releases, put the binary on `PATH`, then:

```sh
rv sync
```

Without `rv`, `.Rprofile` prints `rv is not installed!` on every chunk and R falls back to the packages on the system library path.

### 2. Restore the Python helper environment

All Python tooling lives in `scripts/`:

```sh
cd scripts
uv sync
```

The environment is pinned to Python `3.13` via `scripts/.python-version`.

## Common Commands

Fast render, everything except the catalog:

```sh
quarto render
```

Live preview, rebuilds the page you edited:

```sh
quarto preview
```

One page plus whatever lists it:

```sh
quarto render posts/my-post/index.qmd
```

Full published site, catalog included:

```sh
quarto render --profile full
```

Backfill resource metadata locally:

```sh
cd scripts
uv run python backfill.py --mode both
```

## Freeze

`execute: freeze: auto` caches chunk results in `_freeze/`; `_freeze/posts/` and `_freeze/site_libs/` are committed, the rest stays local. Delete an entry to force that chunk to run again. `.gitignore` records why the catalog is excluded.

## Automation

- `.github/workflows/site.yml`: `quarto render --profile full` on pull requests (checks that repo-only documents are not published and that the CV PDFs and catalog exist) and on pushes to `prod`, which deploys to GitHub Pages

## Notes

- `docs/` is generated output. Do not edit or commit it manually.
- `catalog/resources.txt` is the source of truth for the resources catalog. See [CONTRIBUTING.md](CONTRIBUTING.md).
- `scripts/make_covers.py` regenerates the post cover SVGs in `assets/images/covers/`.
- If a render dies partway (OOM, Ctrl-C), delete `.quarto/` and render again.
