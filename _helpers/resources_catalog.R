`%||%` <- function(a, b) if (!is.null(a)) a else b

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

    block_lines <- raw[start:end]
    parsed <- tryCatch(
      yaml::yaml.load(paste(block_lines, collapse = "\n")),
      error = function(e) NULL
    )
    if (!is.null(parsed)) {
      records[[i]] <- parsed
    }
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
    if (any(cats %in% super_rules[[name]])) {
      return(name)
    }
  }

  "General"
}

load_resources_catalog <- function(path) {
  parse_resources_md(path) |>
    dplyr::mutate(
      language = stringr::str_replace_all(language, ",\\s*", ";"),
      super = purrr::map_chr(category, assign_super)
    ) |>
    dplyr::arrange(type, title)
}

format_date_display <- function(date_str) {
  if (is.na(date_str) || date_str == "") {
    return("")
  }

  month_names <- c(
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  )
  parts <- stringr::str_split_1(date_str, "-")

  if (length(parts) == 3) {
    day <- as.integer(parts[3])
    month <- suppressWarnings(as.integer(parts[2]))
    year <- parts[1]
    if (!is.na(month) && month >= 1 && month <= 12) {
      return(paste(day, month_names[month], year))
    }
  } else if (length(parts) == 2) {
    month <- suppressWarnings(as.integer(parts[2]))
    year <- parts[1]
    if (!is.na(month) && month >= 1 && month <= 12) {
      return(paste(month_names[month], year))
    }
  }

  date_str
}

type_color <- function(type) {
  switch(
    type,
    "Package" = ,
    "Tool" = ,
    "App" = ,
    "Platform" = ,
    "Repository" = "primary",
    "Course" = ,
    "Tutorial" = ,
    "Guide" = ,
    "Workshop" = "success",
    "Book" = ,
    "Documentation" = ,
    "Paper" = ,
    "Journal" = ,
    "Magazine" = ,
    "Slides" = "info",
    "Blog" = ,
    "Website" = ,
    "Video" = ,
    "Gallery" = "warning",
    "Community" = ,
    "Forum" = ,
    "Conference" = ,
    "Social" = ,
    "Newsletter" = "secondary",
    "dark"
  )
}

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

cat_chips <- function(cat_str, uid, max_shown = 3L) {
  if (is.na(cat_str) || cat_str == "") {
    return(NULL)
  }

  parts <- stringr::str_split_1(cat_str, ";") |> stringr::str_trim()
  shown <- parts[seq_len(min(max_shown, length(parts)))]
  extra <- if (length(parts) > max_shown) parts[(max_shown + 1L):length(parts)] else character(0L)
  extra_id <- paste0("extra-", uid)

  visible_chips <- purrr::map(shown, function(category) {
    htmltools::tags$span(class = "chip chip-cat", category)
  })

  if (length(extra) == 0L) {
    return(visible_chips)
  }

  extra_chips <- purrr::map(extra, function(category) {
    htmltools::tags$span(
      class = "chip chip-cat d-none",
      `data-extra` = extra_id,
      category
    )
  })

  expand_btn <- htmltools::tags$button(
    class = "category-expand-toggle",
    type = "button",
    `data-id` = extra_id,
    paste0("+", length(extra))
  )

  list(visible_chips, extra_chips, expand_btn)
}

make_resource_card <- function(row, uid) {
  row <- purrr::map(as.list(row), function(value) {
    if (length(value) == 0 || is.na(value[[1]])) {
      return("")
    }
    as.character(value[[1]])
  })

  type <- row$type %||% ""
  title_text <- row$title %||% ""
  link <- row$link %||% ""
  lang_str <- row$language %||% ""
  cat_str <- row$category %||% ""
  super <- row$super %||% ""
  desc <- row$description %||% ""
  date_raw <- row$date %||% ""
  date_display <- format_date_display(date_raw)

  data_attrs <- list(
    class = "catalog-item",
    `data-type` = tolower(type),
    `data-language` = tolower(lang_str),
    `data-categories` = tolower(cat_str),
    `data-super` = tolower(super),
    `data-date` = date_raw
  )

  badge <- htmltools::tags$span(
    class = paste0("badge resource-type bg-", type_color(type)),
    type
  )

  title_link <- htmltools::tags$a(
    href = link,
    target = "_blank",
    rel = "noopener noreferrer",
    title_text
  )

  description_el <- if (nzchar(desc)) {
    htmltools::tags$p(class = "resource-desc", desc)
  } else {
    NULL
  }

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
              htmltools::tags$div(class = "resource-language-chips", lang_chip(lang_str))
            ),
            htmltools::tags$div(
              class = "resource-title-row",
              htmltools::tags$div(class = "resource-title", title_link),
              date_el
            ),
            description_el,
            htmltools::tags$div(
              class = "cat-chips",
              c(cat_chips(cat_str, uid))
            )
          )
        )
      )
    )
  )
}
