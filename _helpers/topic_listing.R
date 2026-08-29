# ── Topic listing helper ────────────────────────────────────────────────
# Reads post YAML frontmatter, filters by categories, returns HTML grid.
# Used by topics/*.qmd pages.

source(here::here("_helpers", "profile_render.R"))

read_post_meta <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  if (lines[1] != "---") {
    return(NULL)
  }
  end <- which(lines == "---")[2]
  if (is.na(end)) {
    return(NULL)
  }
  meta <- yaml::yaml.load(paste(lines[2:(end - 1)], collapse = "\n"))
  meta$path <- path
  meta
}

match_category <- function(post_cats, wanted) {
  # post_cats is a character vector from categories field
  # wanted is a character vector of category values to match
  any(tolower(post_cats) %in% tolower(wanted))
}

filter_posts_by_categories <- function(wanted_categories) {
  post_files <- Sys.glob(here::here("posts", "*", "index.qmd"))
  posts <- lapply(post_files, read_post_meta)
  posts <- Filter(Negate(is.null), posts)

  # Filter by categories
  matched <- Filter(
    function(p) {
      cats <- p$categories
      if (is.null(cats)) {
        return(FALSE)
      }
      match_category(cats, wanted_categories)
    },
    posts
  )

  # Sort by date descending
  dates <- sapply(matched, function(p) p$date %||% "")
  matched <- matched[order(dates, decreasing = TRUE, na.last = TRUE)]

  matched
}

make_topic_card <- function(post, index) {
  title <- post$title %||% ""
  desc <- post$description %||% ""
  date_raw <- post$date %||% ""
  slug <- basename(dirname(post$path))
  href <- paste0("../posts/", slug, "/index.html")
  reading_time <- post$`reading-time` %||% NA

  date_display <- if (nzchar(date_raw)) {
    d <- as.Date(date_raw)
    format(d, "%B %d, %Y")
  } else {
    ""
  }

  # Format reading time
  rt_text <- if (!is.na(reading_time)) paste0(reading_time, " min") else ""

  htmltools::tags$div(
    class = "g-col-12 g-col-md-6 g-col-lg-4",
    htmltools::tags$a(
      href = href,
      class = "quarto-grid-link",
      htmltools::tags$div(
        class = "quarto-grid-item card h-100 card-left",
        htmltools::tags$div(
          class = "card-body post-contents",
          htmltools::tags$h5(class = "no-anchor card-title listing-title", title),
          if (nzchar(rt_text)) {
            htmltools::tags$div(class = "listing-reading-time card-text text-muted", rt_text)
          },
          if (nzchar(desc)) {
            htmltools::tags$div(
              class = "card-text listing-description delink",
              htmltools::tags$p(desc)
            )
          },
          htmltools::tags$div(
            class = "card-attribution card-text-small end",
            htmltools::tags$div(class = "listing-date", date_display)
          )
        )
      )
    )
  )
}

render_topic <- function(title, description, wanted_categories) {
  posts <- filter_posts_by_categories(wanted_categories)
  cards <- lapply(seq_along(posts), function(i) make_topic_card(posts[[i]], i))

  htmltools::tags$div(
    class = "quarto-listing quarto-listing-container-grid",
    id = "topic-listing",
    htmltools::tags$div(
      class = "list grid quarto-listing-cols-3",
      cards
    ),
    htmltools::tags$p(
      class = "text-muted",
      sprintf("Showing %d post%s", length(posts), if (length(posts) != 1) "s" else "")
    )
  )
}
