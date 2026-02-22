# Contributing to the Resources Catalog

The catalog at [antoinelucasfra.github.io/projects/resources_catalog](https://antoinelucasfra.github.io/projects/resources_catalog.html) is a curated list of data science resources for R, Python, and beyond.

There are two ways to add a resource:

- **Personal workflow** — via a Google Keep note that syncs automatically every Monday (see [Automated workflow](#automated-workflow-google-keep-sync))
- **PR path** — fork the repo, edit `data/resources.txt`, open a pull request (see [Contributing via PR](#contributing-via-pr))

---

## Field Reference

Every entry in `data/resources.txt` is a YAML block with **6 required fields**:

```yaml
---
title: "Mastering Shiny"
type: "Book"
link: "https://mastering-shiny.org/"
language: "R"
category: "Shiny;Web Development"
description: "The online version of Mastering Shiny, a book that teaches you to build production-quality Shiny apps."
---
```

| Field | Required | Description | Example |
|---|---|---|---|
| `title` | yes | Display name of the resource | `"Mastering Shiny"` |
| `type` | yes | Resource classification — see valid values below | `"Book"` |
| `link` | yes | Full URL | `"https://mastering-shiny.org/"` |
| `language` | yes | Programming language(s) — use `;` for multiple | `"R"` or `"R;Python"` |
| `category` | yes | Topical tags — use `;` for multiple, no spaces around `;` | `"Shiny;Web Development"` |
| `description` | yes | One or two sentences describing the resource (max 300 chars) | `"The online version of ..."` |

### Valid `type` values

`Blog` · `Book` · `Website` · `Package` · `Video` · `Paper` · `Course` · `Community` · `Newsletter` · `Conference` · `Forum` · `Journal` · `Repository`

### Valid `language` values

`R` · `Python` · `Other` · or a combination like `R;Python`

### `category` conventions

- Use existing category tags when possible (check the catalog filter chips for current tags)
- Separate multiple tags with `;` and no surrounding spaces: `"Statistics;Mixed Models;GLMM"`
- Tags are case-sensitive as written in the file — use title case

---

## Automated workflow — Google Keep sync

This is the personal day-to-day workflow for adding resources from curation to the catalog without touching any file manually.

### How it works end-to-end

```
You add a line to the Keep note
        ↓
Every Monday 07:00 UTC — GitHub Actions runs sync_keep.py
        ↓
Script parses each line, fetches the URL, extracts a real description
        ↓
Valid new entries are appended to data/resources.txt
        ↓
Processed lines are removed from the Keep note
        ↓
The commit triggers publish.yml → quarto render → GitHub Pages redeploy
```

### Keep note format

Create a note in Google Keep with the title you stored in the `KEEP_NOTE_TITLE` secret. Add one resource per line using **exactly 5 fields separated by ` - `** (space-dash-space):

```
https://mastering-shiny.org/ - Mastering Shiny - Book - R - Shiny;Web Development
https://r4ds.hadley.nz - R for Data Science - Book - R - Statistics;Data Science
https://fastapi.tiangolo.com - FastAPI - Website - Python - Web;API
```

Field order: `URL - Title - Type - Language - Category`

The `description` field is **not** written in the note — it is fetched automatically from the URL by `trafilatura` (og:description → first body sentence → empty).

### What happens to each line

| Outcome | Condition | Action |
|---|---|---|
| **Added** | Valid, not already in catalog | Appended to `resources.txt`, removed from note |
| **Duplicate** | URL already exists in `resources.txt` | Silently removed from note |
| **Kept in note** | Malformed (wrong field count, bad URL, unknown type) | Left in note unchanged — fix and it will be picked up next run |

Invalid lines and a description of why they were skipped appear in the GitHub Actions run summary.

### One-time setup: obtain the master token

`gkeepapi` authenticates with a **master token**, not your password. Obtain it once and store it as a secret.

**Prerequisites:** Docker installed locally.

```sh
docker run --rm -it --entrypoint /bin/sh python:3 -c \
  'pip install gpsoauth
   python3 -c "
import gpsoauth
email = input(\"Email: \")
oauth_token = input(\"OAuth Token: \")
android_id  = input(\"Android ID: \")
print(gpsoauth.exchange_token(email, oauth_token, android_id))
"'
```

To get the **OAuth Token** and **Android ID** needed above, follow the [gpsoauth alternative flow documentation](https://github.com/simon-weber/gpsoauth#alternative-flow).

### GitHub secrets to configure

Go to **GitHub → Settings → Secrets and variables → Actions → New repository secret**:

| Secret name | Value |
|---|---|
| `KEEP_EMAIL` | Your Gmail address |
| `KEEP_MASTER_TOKEN` | The master token obtained above |
| `KEEP_NOTE_TITLE` | Exact title of your curation note in Google Keep |

### Triggering the workflow manually

Go to **GitHub → Actions → Sync Keep → resources → Run workflow**. This is useful to process a batch immediately without waiting for Monday.

### Backfilling descriptions on existing entries

The `backfill_descriptions.py` script replaces all auto-generated placeholder descriptions in `resources.txt` with real ones fetched from each URL. **Run this once locally** — it takes a while (~980 entries × ~0.5 s each).

```sh
# From the repo root
cd scripts/
uv sync
RESOURCES_PATH=../data/resources.txt uv run python backfill_descriptions.py
```

Progress is printed to stdout. When it finishes:

```sh
# Review changes before committing
git diff data/resources.txt

# If happy:
git add data/resources.txt
git commit -m "chore: backfill resource descriptions"
```

Then push through the normal branch → PR flow.

---

## Contributing via PR

If you want to suggest a resource and you are not the repo owner:

1. **Fork** the repository on GitHub
2. **Edit** `data/resources.txt` — add your block at the end of the file, following the exact format:

```yaml
---
title: "Your Resource Title"
type: "Blog"
link: "https://example.com/resource"
language: "R"
category: "Statistics;Tutorial"
description: "A one-sentence description of what this resource is and who it is for."
---
```

3. **Check your block** against the field reference above — all 6 fields are required, values must be double-quoted, multi-values use `;`
4. **Open a pull request** against `main` with a short description of what you are adding and why

Rules:
- One resource per PR is preferred for easy review
- The `description` field should be a genuine human-written sentence, not a template
- Do not edit `data/resources.csv` — it is a derived export, not the source of truth
- Do not edit any file in `docs/` — it is generated by `quarto render`

---

## What NOT to do

- Never edit `docs/` directly — it is generated on every `quarto render` and will be overwritten
- Never edit `data/resources.csv` — it is an export derived from `resources.txt`
- Never hardcode credentials, tokens, or email addresses in source files
- Never commit `.env` files or any file containing secrets
- Never run `git add .` without reviewing staged changes first
