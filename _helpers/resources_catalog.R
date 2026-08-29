`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── Parse resources.txt (--- delimited YAML blocks) ─────────────────────
parse_resources_md <- function(path) {
  raw <- readLines(path, encoding = "UTF-8")
  sep_idx <- which(raw == "---")
  if (length(sep_idx) < 2) {
    return(tibble::tibble())
  }

  records <- vector("list", floor(length(sep_idx) / 2))
  for (i in seq_len(floor(length(sep_idx) / 2))) {
    start <- sep_idx[2 * i - 1] + 1L
    end <- sep_idx[2 * i] - 1L
    if (start > end) {
      next
    }
    parsed <- tryCatch(
      yaml::yaml.load(paste(raw[start:end], collapse = "\n")),
      error = function(e) NULL
    )
    if (!is.null(parsed)) records[[i]] <- parsed
  }
  records <- Filter(Negate(is.null), records)

  dplyr::bind_rows(lapply(records, function(record) {
    tibble::tibble(
      type = as.character(record$type %||% ""),
      title = as.character(record$title %||% ""),
      link = as.character(record$link %||% ""),
      language = as.character(record$language %||% ""),
      category = as.character(record$category %||% ""),
      description = as.character(record$description %||% ""),
      date = as.character(record$date %||% "")
    )
  }))
}

# ── Super-category lookup: category keyword → parent group ──────────────
# ponytail: inline data, fine for ~80 rarely-changing keywords
super_rules <- list(
  "Machine Learning & AI" = c(
    "machine learning",
    "deep learning",
    "nlp",
    "computer vision",
    "neural",
    "transformer",
    "gan",
    "llm",
    "llms",
    "diffusion",
    "mlops",
    "ai",
    "artificial intelligence",
    "reinforcement learning",
    "classification",
    "clustering",
    "feature engineering"
  ),
  "Statistics" = c(
    "statistics",
    "bayesian",
    "bayesian statistics",
    "mixed model",
    "mixed models",
    "meta-analysis",
    "survival",
    "longitudinal",
    "glmm",
    "causal",
    "spc",
    "regression",
    "econometrics",
    "time series",
    "factor analysis",
    "probability",
    "inference",
    "frequentist",
    "sampling",
    "simulation"
  ),
  "R & Shiny" = c(
    "shiny",
    "r markdown",
    "quarto",
    "renv",
    "golem",
    "ggplot2",
    "tidyverse",
    "web development",
    "ggplot",
    "flexdashboard",
    "pkgdown",
    "testthat",
    "devtools",
    "usethis",
    "programming",
    "r package",
    "tidyr",
    "purrr",
    "dplyr"
  ),
  "Data Visualization" = c(
    "visualization",
    "data visualization",
    "charts",
    "gallery",
    "color",
    "dashboard",
    "dashboards",
    "plot",
    "mapping",
    "cartography",
    "infographic",
    "d3",
    "plotly",
    "leaflet",
    "ggplot2",
    "highcharts",
    "vega"
  ),
  "Python & DevOps" = c(
    "python",
    "docker",
    "git",
    "github actions",
    "deployment",
    "reproducibility",
    "workflow",
    "best practices",
    "devops",
    "kubernetes",
    "terraform",
    "ci/cd",
    "containers",
    "version control",
    "github",
    "automation"
  ),
  "Education" = c(
    "tutorial",
    "course",
    "education",
    "guide",
    "reference",
    "learning",
    "book",
    "books",
    "presentation",
    "presentations",
    "workshop",
    "cheatsheet",
    "exercises"
  ),
  "Community & Events" = c(
    "community",
    "conference",
    "forum",
    "french",
    "social",
    "newsletter",
    "blog",
    "meetup",
    "podcast"
  ),
  "Life Sciences" = c(
    "pharma",
    "clinical",
    "ecology",
    "bioinformatics",
    "psychology",
    "genetics",
    "biomedical",
    "behavioral",
    "neuroscience",
    "health",
    "epidemiology",
    "genomics",
    "proteomics"
  ),
  "Research" = c(
    "research",
    "paper",
    "preprint",
    "journal",
    "academic",
    "arxiv",
    "publication",
    "reproducible research",
    "open science"
  )
)

assign_super <- function(category_str) {
  if (is.na(category_str) || category_str == "") {
    return("General")
  }
  cats <- stringr::str_split_1(category_str, ";") |>
    stringr::str_trim() |>
    tolower()
  for (name in names(super_rules)) {
    if (any(cats %in% super_rules[[name]])) return(name)
  }
  "General"
}

# ── Data mappings ───────────────────────────────────────────────────────
# ponytail: named vectors, not switches

TYPE_COLORS <- c(
  "Package" = "primary",
  "Tool" = "primary",
  "App" = "primary",
  "Platform" = "primary",
  "Repository" = "primary",
  "Course" = "success",
  "Tutorial" = "success",
  "Guide" = "success",
  "Workshop" = "success",
  "Book" = "info",
  "Documentation" = "info",
  "Paper" = "info",
  "Journal" = "info",
  "Magazine" = "info",
  "Slides" = "info",
  "Blog" = "warning",
  "Website" = "warning",
  "Video" = "warning",
  "Gallery" = "warning",
  "Community" = "secondary",
  "Forum" = "secondary",
  "Conference" = "secondary",
  "Social" = "secondary",
  "Newsletter" = "secondary"
)

type_color <- function(type) {
  if (is.na(type)) {
    return("dark")
  }
  r <- TYPE_COLORS[type]
  if (is.na(r)) "dark" else r
}

LANG_CHIP_STYLES <- c(
  "r" = "color: #1a579d; border-color: rgba(26,87,157,0.4);",
  "python" = "color: #3a7a20; border-color: rgba(55,125,34,0.4);",
  "julia" = "color: #8b33b3; border-color: rgba(149,57,191,0.4);",
  "other" = "color: #555f6a; border-color: rgba(108,117,125,0.35);"
)

SUPER_CHIP_LABELS <- c(
  "machine learning & ai" = "ML & AI",
  "statistics" = "Statistics",
  "r & shiny" = "R & Shiny",
  "data visualization" = "Viz",
  "python & devops" = "Python & DevOps",
  "education" = "Education",
  "community & events" = "Community",
  "life sciences" = "Life Sciences",
  "research" = "Research",
  "general" = "General"
)

# ── Load and prepare catalog data ───────────────────────────────────────
load_resources_catalog <- function(path) {
  parse_resources_md(path) |>
    dplyr::mutate(
      language = stringr::str_replace_all(language, ",\\s*", ";"),
      super = purrr::map_chr(category, assign_super)
    ) |>
    dplyr::arrange(type, title)
}

# ── Display helpers ────────────────────────────────────────────────────
format_date_display <- function(date_str) {
  if (is.na(date_str) || date_str == "") {
    return("")
  }
  parts <- stringr::str_split_1(date_str, "-")
  if (length(parts) == 3) {
    day <- suppressWarnings(as.integer(parts[3]))
    month <- suppressWarnings(as.integer(parts[2]))
    year <- parts[1]
    if (!is.na(day) && !is.na(month) && month >= 1 && month <= 12) {
      return(paste(day, month.abb[month], year))
    }
  } else if (length(parts) == 2) {
    month <- suppressWarnings(as.integer(parts[2]))
    year <- parts[1]
    if (!is.na(month) && month >= 1 && month <= 12) {
      return(paste(month.abb[month], year))
    }
  }
  date_str
}

normalise_date <- function(date_str) {
  if (is.na(date_str) || date_str == "") {
    return("")
  }
  parts <- stringr::str_split_1(date_str, "-")
  if (length(parts) == 3) {
    values <- suppressWarnings(as.integer(parts))
    if (!anyNA(values) && values[2] %in% 1:12 && values[3] %in% 1:31) {
      return(sprintf("%04d-%02d-%02d", values[1], values[2], values[3]))
    }
  }
  if (length(parts) == 2) {
    values <- suppressWarnings(as.integer(parts))
    if (!anyNA(values) && values[2] %in% 1:12) {
      return(sprintf("%04d-%02d-01", values[1], values[2]))
    }
  }
  ""
}

resource_domain <- function(link) {
  if (is.na(link) || link == "") {
    return("")
  }
  host <- sub("^https?://([^/?#]+).*$", "\\1", link, ignore.case = TRUE)
  host <- sub(":[0-9]+$", "", host)
  host <- sub("^www\\.", "", host, ignore.case = TRUE)
  if (grepl("^[A-Za-z0-9.-]+$", host)) stringr::str_to_lower(host) else ""
}

# ── Language chip (one span per language) ──────────────────────────────
lang_chip <- function(lang_str) {
  if (is.na(lang_str) || lang_str == "") {
    return(NULL)
  }
  parts <- stringr::str_split_1(lang_str, ";") |> stringr::str_trim()
  purrr::map(parts, function(lang) {
    chip_class <- switch(
      tolower(lang),
      r = "chip chip-r",
      python = "chip chip-python",
      julia = "chip chip-julia",
      "chip chip-other"
    )
    htmltools::tags$span(class = chip_class, lang)
  })
}

# ── Category chips (one span per category, all visible) ────────────────
cat_chips <- function(cat_str) {
  if (is.na(cat_str) || cat_str == "") {
    return(NULL)
  }
  parts <- stringr::str_split_1(cat_str, ";") |> stringr::str_trim()
  purrr::map(parts, function(category) {
    htmltools::tags$span(class = "chip chip-cat", category)
  })
}

# ── Render one resource card ────────────────────────────────────────────
make_resource_card <- function(row, uid) {
  row <- purrr::map(as.list(row), function(value) {
    if (length(value) == 0 || is.na(value[[1]])) {
      return("")
    }
    as.character(value[[1]])
  })

  date_norm <- normalise_date(row$date %||% "")
  search_terms <- paste(
    row$title %||% "",
    row$description %||% "",
    row$category %||% "",
    row$type %||% "",
    resource_domain(row$link %||% ""),
    sep = " "
  )

  data_attrs <- list(
    class = "catalog-item",
    `data-type` = tolower(row$type %||% ""),
    `data-language` = tolower(row$language %||% ""),
    `data-categories` = tolower(row$category %||% ""),
    `data-super` = tolower(row$super %||% ""),
    `data-date` = date_norm,
    `data-search` = tolower(search_terms),
    `data-domain` = resource_domain(row$link %||% "")
  )

  badge <- htmltools::tags$span(
    class = paste0("badge resource-type bg-", type_color(row$type %||% "")),
    row$type %||% ""
  )

  title_link <- htmltools::tags$a(
    href = row$link %||% "",
    target = "_blank",
    rel = "noopener noreferrer",
    row$title %||% ""
  )

  desc <- row$description %||% ""
  description_el <- if (nzchar(desc)) htmltools::tags$p(class = "resource-desc", desc) else NULL

  date_raw <- row$date %||% ""
  date_display <- format_date_display(date_raw)
  date_el <- if (nzchar(date_display)) {
    htmltools::tags$span(class = "resource-date", date_display)
  } else {
    NULL
  }

  do.call(
    htmltools::tags$article,
    c(
      data_attrs,
      list(
        htmltools::tags$div(
          class = "card resource-card h-100",
          htmltools::tags$div(
            class = "card-body",
            htmltools::tags$div(
              class = "resource-meta-row",
              badge,
              htmltools::tags$div(
                class = "resource-language-chips",
                lang_chip(row$language %||% "")
              )
            ),
            htmltools::tags$div(
              class = "resource-title-row",
              htmltools::tags$div(class = "resource-title", title_link),
              date_el
            ),
            description_el,
            htmltools::tags$div(class = "cat-chips", c(cat_chips(row$category %||% "")))
          )
        )
      )
    )
  )
}
