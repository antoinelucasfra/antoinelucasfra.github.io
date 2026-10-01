#' CV variants share one profile: `data/profile.yml`.
cv_variants <- c("ai", "biostat")

load_profile <- function(variant = NULL, path = here::here("data", "profile.yml")) {
  profile <- yaml::read_yaml(path)

  if (is.null(variant)) {
    return(profile)
  }

  profile <- apply_variant(profile, variant)
  profile$skills <- order_skills(profile$skills)
  profile
}

#' Overlay a CV variant on the base profile.
#'
#' A key suffixed `_<variant>` overrides its unsuffixed sibling, at any depth:
#' `identity.title_biostat`, `summary.cv_ai`, `experience[[i]]$bullets_biostat`.
#' Keys belonging to any known variant are dropped, so nothing suffixed reaches a renderer.
apply_variant <- function(x, variant, variants = cv_variants) {
  if (!is.list(x)) {
    return(x)
  }

  suffix <- paste0("_", variant)
  keys <- names(x) %||% rep("", length(x))
  hit <- vapply(
    keys,
    function(key) any(endsWith(key, paste0("_", variants))),
    logical(1)
  )
  overlays <- x[hit]
  x <- x[!hit]

  if (!is.null(names(x))) {
    names(x) <- keys[!hit]
  }

  for (key in names(overlays)) {
    if (endsWith(key, suffix)) {
      x[[sub(suffix, "", key, fixed = TRUE)]] <- overlays[[key]]
    }
  }

  lapply(x, apply_variant, variant = variant)
}

#' Skill groups carry `order` / `order_<variant>` to control CV section order.
#' Groups without an order keep their position last.
order_skills <- function(skills) {
  ranks <- vapply(skills, function(group) group$order %||% Inf, numeric(1))
  skills[order(ranks)]
}

external_link_attrs <- list(target = "_blank", rel = "noopener noreferrer")

icon_link <- function(href, icon, label, extra_class = NULL, external = FALSE) {
  classes <- c("hero-link", extra_class)
  attrs <- list(
    href = href,
    class = paste(classes[!is.na(classes) & nzchar(classes)], collapse = " ")
  )

  if (external) {
    attrs <- c(attrs, external_link_attrs)
  }

  do.call(
    htmltools::tags$a,
    c(
      attrs,
      list(
        htmltools::tags$i(class = paste("bi", icon)),
        label
      )
    )
  )
}

render_homepage <- function(profile) {
  identity <- profile$identity
  current_role <- profile$home$current_role
  n_posts <- length(list.dirs(here::here("posts"), recursive = FALSE))
  stats <- list(
    list(value = "5+", label = "years in pharma & cosmetics R&D"),
    list(value = "20+", label = "production Shiny apps supported"),
    list(value = "100+", label = "clinical studies analysed"),
    list(value = paste0(n_posts, "+"), label = "field notes published")
  )

  htmltools::tagList(
    htmltools::tags$div(
      class = "hero-grid",
      htmltools::tags$div(
        class = "hero-photo-col",
        htmltools::tags$img(
          src = identity$photo,
          alt = "Portrait of Antoine Lucas",
          class = "hero-img"
        )
      ),
      htmltools::tags$div(
        class = "hero-text-col",
        htmltools::tags$div(class = "hero-name", identity$name),
        htmltools::tags$div(class = "hero-tagline", identity$title),
        htmltools::tags$div(
          class = "hero-location",
          htmltools::tags$i(class = "bi bi-geo-alt-fill", `aria-hidden` = "true"),
          htmltools::tags$span(identity$location_short)
        ),
        htmltools::tags$div(
          class = "hero-links",
          icon_link(paste0("mailto:", identity$email), "bi-envelope-fill", "Email"),
          icon_link(identity$linkedin, "bi-linkedin", "LinkedIn", external = TRUE),
          icon_link(identity$github, "bi-github", "GitHub", external = TRUE),
          icon_link(identity$mastodon, "bi-mastodon", "Fosstodon", external = TRUE),
          icon_link("/cv.html", "bi-file-earmark-text", "CV", extra_class = "hero-link-cv")
        )
      )
    ),
    htmltools::tags$hr(),
    lapply(profile$home$intro, function(paragraph) htmltools::tags$p(paragraph)),
    htmltools::tags$div(
      class = "highlight",
      htmltools::tags$p(
        "Currently ",
        htmltools::tags$strong(
          paste(current_role$title, "at", current_role$organisation)
        ),
        ", ",
        current_role$context,
        ". ",
        current_role$summary
      )
    ),
    htmltools::tags$div(
      class = "stats-band",
      lapply(
        stats,
        function(s) {
          htmltools::tags$div(
            class = "stat-item",
            htmltools::tags$div(class = "stat-value", s$value),
            htmltools::tags$div(class = "stat-label", s$label)
          )
        }
      )
    ),
    htmltools::tags$h2(class = "section-heading", "What I do"),
    htmltools::tags$div(
      class = "what-i-do",
      lapply(
        profile$home$what_i_do,
        function(item) {
          htmltools::tags$div(
            class = "wid-item",
            htmltools::tags$h3(item$title),
            htmltools::tags$p(item$body)
          )
        }
      )
    ),
    htmltools::tags$h2(class = "section-heading", "Selected proof"),
    htmltools::tags$div(
      class = "proof-grid",
      lapply(
        profile$home$selected_proof,
        function(item) {
          htmltools::tags$a(
            class = "proof-card",
            href = item$href,
            htmltools::tags$h3(item$title),
            htmltools::tags$p(item$description),
            htmltools::tags$span(
              class = "proof-card-more",
              "Read →"
            )
          )
        }
      )
    ),
    htmltools::tags$h2(class = "section-heading", "How I work"),
    htmltools::tags$div(
      class = "principles-grid",
      lapply(
        profile$home$work_principles,
        function(item) {
          htmltools::tags$div(
            class = "principle-item",
            htmltools::tags$p(
              htmltools::tags$strong(item$label),
              " ",
              item$body
            )
          )
        }
      )
    ),
    htmltools::tags$h2(class = "section-heading", "Skills"),
    htmltools::tags$div(
      class = "skill-section",
      lapply(
        profile$skills,
        function(group) {
          htmltools::tags$div(
            class = "skill-group",
            htmltools::tags$p(htmltools::tags$strong(group$label)),
            htmltools::tags$div(
              class = "skill-pills",
              lapply(
                group$items,
                function(item) htmltools::tags$span(class = "pill", item)
              )
            )
          )
        }
      )
    ),
    htmltools::tags$h2(class = "section-heading education", "Education"),
    htmltools::tags$ul(
      lapply(
        profile$education,
        function(entry) {
          htmltools::tags$li(
            htmltools::tags$strong(entry$degree),
            " — ",
            htmltools::tags$em(entry$school),
            " · ",
            htmltools::tags$em(entry$year)
          )
        }
      )
    ),
    htmltools::tags$hr(),
    htmltools::tags$div(
      class = "site-nav-footer",
      icon_link("/blog.html", "bi-pencil", "Blog"),
      " · field notes from real work · ",
      icon_link("/projects.html", "bi-folder", "Projects"),
      " · ",
      icon_link("/cv.html", "bi-file-earmark-text", "Full CV")
    )
  )
}

render_about_story <- function(profile) {
  htmltools::tagList(
    lapply(profile$about$story, function(paragraph) htmltools::tags$p(paragraph))
  )
}

render_about_work_focus <- function(profile) {
  htmltools::tagList(
    lapply(
      profile$about$work_focus,
      function(item) {
        htmltools::tags$p(
          htmltools::tags$strong(item$label),
          " ",
          item$body
        )
      }
    )
  )
}

render_about_contact <- function(profile) {
  identity <- profile$identity

  htmltools::tagList(
    htmltools::tags$ul(
      htmltools::tags$li(
        htmltools::tags$strong("Email"),
        ": ",
        htmltools::tags$a(href = paste0("mailto:", identity$email), identity$email)
      ),
      htmltools::tags$li(
        htmltools::tags$strong("LinkedIn"),
        ": ",
        do.call(
          htmltools::tags$a,
          c(
            list(href = identity$linkedin),
            external_link_attrs,
            list(sub("^https://", "", identity$linkedin))
          )
        )
      ),
      htmltools::tags$li(
        htmltools::tags$strong("GitHub"),
        ": ",
        do.call(
          htmltools::tags$a,
          c(
            list(href = identity$github),
            external_link_attrs,
            list(sub("^https://", "", identity$github))
          )
        )
      ),
      htmltools::tags$li(
        htmltools::tags$strong("Fosstodon"),
        ": ",
        do.call(
          htmltools::tags$a,
          c(
            list(href = identity$mastodon),
            external_link_attrs,
            list("@antoineloucass")
          )
        )
      )
    ),
    htmltools::tags$p(
      "Content on this site is licensed under ",
      do.call(
        htmltools::tags$a,
        c(
          list(href = "https://creativecommons.org/licenses/by-nc-sa/4.0/"),
          external_link_attrs,
          list("CC BY NC SA 4.0")
        )
      ),
      " unless stated otherwise."
    )
  )
}


render_cv_entry_html <- function(entry) {
  htmltools::tags$div(
    class = "cv-entry",
    htmltools::tags$div(
      class = "cv-entry-head",
      htmltools::tags$div(
        class = "cv-entry-meta",
        htmltools::tags$p(
          htmltools::tags$span(class = "cv-role", entry$role),
          htmltools::tags$span(class = "cv-org", entry$organisation)
        )
      ),
      htmltools::tags$p(class = "cv-period", entry$period)
    ),
    if (!is.null(entry$bullets)) {
      htmltools::tags$ul(
        lapply(entry$bullets, function(item) htmltools::tags$li(item))
      )
    } else {
      htmltools::tags$p(class = "cv-inline-text", entry$summary)
    }
  )
}

render_cv_html <- function(profile) {
  identity <- profile$identity
  selected_experience <- Filter(
    function(entry) identical(entry$section, "selected"),
    profile$experience
  )
  earlier_experience <- Filter(
    function(entry) identical(entry$section, "earlier"),
    profile$experience
  )

  htmltools::tags$div(
    class = "cv-page",
    htmltools::tags$header(
      class = "cv-header",
      htmltools::tags$div(
        class = "cv-header-text",
        htmltools::tags$h1(class = "cv-name", identity$name),
        htmltools::tags$p(class = "cv-title", identity$title),
        htmltools::tags$p(
          class = "cv-subtitle",
          paste(identity$sectors, identity$location_full, sep = " · ")
        ),
        htmltools::tags$div(
          class = "cv-contacts",
          do.call(
            htmltools::tags$a,
            c(
              list(href = paste0("mailto:", identity$email)),
              list(
                htmltools::tags$i(class = "bi bi-envelope-fill"),
                identity$email
              )
            )
          ),
          do.call(
            htmltools::tags$a,
            c(
              list(href = identity$linkedin),
              external_link_attrs,
              list(
                htmltools::tags$i(class = "bi bi-linkedin"),
                sub("^https://", "", identity$linkedin)
              )
            )
          ),
          do.call(
            htmltools::tags$a,
            c(
              list(href = identity$github),
              external_link_attrs,
              list(
                htmltools::tags$i(class = "bi bi-github"),
                sub("^https://", "", identity$github)
              )
            )
          ),
          do.call(
            htmltools::tags$a,
            c(
              list(href = profile$identity$cv_pdf %||% "cv.pdf"),
              external_link_attrs,
              list(
                htmltools::tags$i(class = "bi bi-file-earmark-pdf"),
                "Download PDF"
              )
            )
          )
        )
      ),
      htmltools::tags$div(
        class = "cv-header-photo",
        htmltools::tags$img(
          src = identity$photo,
          alt = "Portrait of Antoine Lucas",
          class = "cv-photo"
        )
      )
    ),
    htmltools::tags$div(class = "cv-rule"),
    htmltools::tags$p(class = "cv-summary", profile$summary$cv),
    htmltools::tags$h2(class = "cv-section-title", "Experience"),
    lapply(selected_experience, render_cv_entry_html),
    htmltools::tags$h2(class = "cv-section-title", "Earlier experience"),
    lapply(earlier_experience, render_cv_entry_html),
    htmltools::tags$h2(class = "cv-section-title", "Education"),
    lapply(
      profile$education,
      function(entry) {
        htmltools::tags$div(
          class = "cv-entry cv-entry-edu",
          htmltools::tags$div(
            class = "cv-entry-head",
            htmltools::tags$div(
              class = "cv-entry-meta",
              htmltools::tags$p(
                htmltools::tags$span(class = "cv-role", entry$degree),
                htmltools::tags$span(class = "cv-org", entry$school)
              )
            ),
            htmltools::tags$p(class = "cv-period", entry$year)
          )
        )
      }
    ),
    htmltools::tags$h2(class = "cv-section-title", "Technical Skills"),
    htmltools::tags$div(
      class = "cv-skills-grid",
      lapply(
        profile$skills,
        function(group) {
          htmltools::tags$div(
            class = "cv-skill-row",
            htmltools::tags$span(class = "cv-skill-label", group$label),
            htmltools::tags$span(class = "cv-skill-value", paste(group$items, collapse = " · "))
          )
        }
      )
    ),
    htmltools::tags$div(
      class = "cv-inline-sections",
      htmltools::tags$div(
        class = "cv-inline-section",
        htmltools::tags$h2(class = "cv-section-title", "Certifications"),
        lapply(
          profile$additional$certifications,
          function(item) htmltools::tags$p(class = "cv-inline-text", item)
        )
      ),
      htmltools::tags$div(
        class = "cv-inline-section",
        htmltools::tags$h2(class = "cv-section-title", "Languages"),
        lapply(
          profile$additional$languages,
          function(item) htmltools::tags$p(class = "cv-inline-text", item)
        )
      )
    )
  )
}

typst_escape <- function(text) {
  escaped <- gsub("\\\\", "\\\\\\\\", text)
  escaped <- gsub("@", "\\\\@", escaped, fixed = TRUE)
  escaped <- gsub("\\[", "\\\\[", escaped)
  escaped <- gsub("\\]", "\\\\]", escaped)
  escaped
}

typst_bracket <- function(text) {
  paste0("[", typst_escape(text), "]")
}

render_cv_typst_entry <- function(entry) {
  c(
    "#entry(",
    paste0("  ", typst_bracket(entry$role), ","),
    paste0("  ", typst_bracket(entry$organisation), ","),
    paste0("  ", typst_bracket(entry$period), ","),
    "  [",
    paste0("    - ", typst_escape(unlist(entry$bullets))),
    "  ],",
    ")"
  )
}

render_cv_typst_intern <- function(entry) {
  c(
    "#intern_entry(",
    paste0("  ", typst_bracket(entry$role), ","),
    paste0("  ", typst_bracket(entry$organisation), ","),
    paste0("  ", typst_bracket(entry$period), ","),
    paste0("  ", typst_bracket(entry$summary), ","),
    ")"
  )
}

render_cv_typst_education <- function(entry) {
  c(
    "#edu_entry(",
    paste0("  ", typst_bracket(entry$degree), ","),
    paste0("  ", typst_bracket(entry$school), ","),
    paste0("  ", typst_bracket(entry$year), ","),
    ")"
  )
}

render_cv_typst_skill <- function(group) {
  paste0(
    "#skill_row(",
    typst_bracket(group$label),
    ", ",
    typst_bracket(paste(group$items, collapse = " · ")),
    ")"
  )
}

render_cv_typst_detail_block <- function(title, items, trailing_comma = FALSE) {
  block_lines <- c(
    "  block[",
    paste0("    #text(weight: \"bold\", size: 9.5pt)[", typst_escape(title), "]"),
    "    #v(5pt)"
  )

  for (index in seq_along(items)) {
    if (index > 1) {
      block_lines <- c(block_lines, "    #v(3pt)")
    }

    block_lines <- c(
      block_lines,
      paste0("    #text(size: 9pt)[", typst_escape(items[[index]]), "]")
    )
  }

  closing_line <- if (trailing_comma) "  ]," else "  ]"
  c(block_lines, closing_line)
}

render_cv_typst <- function(profile) {
  identity <- profile$identity
  selected_experience <- Filter(
    function(entry) identical(entry$section, "selected"),
    profile$experience
  )
  earlier_experience <- Filter(
    function(entry) identical(entry$section, "earlier"),
    profile$experience
  )

  header <- c(
    "#grid(",
    "  columns: (1fr, auto),",
    "  column-gutter: 14pt,",
    "  block(below: 0pt)[",
    paste0(
      "    #text(weight: \"bold\", size: 23pt, fill: navy)[",
      typst_escape(identity$name),
      "]"
    ),
    "    #v(4pt)",
    paste0(
      "    #text(weight: \"bold\", size: 11pt, fill: gold)[",
      typst_escape(identity$title),
      "]"
    ),
    "    #v(3pt)",
    paste0(
      "    #text(size: 9pt, fill: slate)[",
      typst_escape(paste(identity$sectors, identity$location_full, sep = " · ")),
      "]"
    ),
    "  ],",
    "  align(right + horizon)[",
    paste0(
      "    #text(size: 9pt)[#link(\"mailto:",
      identity$email,
      "\")[",
      typst_escape(sub("@", " (at) ", identity$email, fixed = TRUE)),
      "]]"
    ),
    "    #linebreak()",
    paste0(
      "    #text(size: 9pt)[#link(\"",
      identity$linkedin,
      "\")[",
      typst_escape(sub("^https://", "", identity$linkedin)),
      "]]"
    ),
    "    #linebreak()",
    paste0(
      "    #text(size: 9pt)[#link(\"",
      identity$github,
      "\")[",
      typst_escape(sub("^https://", "", identity$github)),
      "]]"
    ),
    "  ],",
    ")",
    "",
    "#v(8pt)",
    "#line(length: 100%, stroke: (paint: gold, thickness: 1pt))",
    "#v(8pt)"
  )

  summary_block <- c(
    "#block(fill: mist, inset: (x: 11pt, y: 9pt), radius: 5pt, width: 100%)[",
    paste0("  #text(size: 9.2pt)[", typst_escape(profile$summary$cv), "]"),
    "]"
  )

  selected_block <- unlist(lapply(selected_experience, render_cv_typst_entry), use.names = FALSE)
  earlier_block <- unlist(lapply(earlier_experience, render_cv_typst_intern), use.names = FALSE)
  education_block <- unlist(lapply(profile$education, render_cv_typst_education), use.names = FALSE)
  skills_block <- vapply(profile$skills, render_cv_typst_skill, character(1))

  additional_block <- c(
    "#section([Additional Information])",
    "",
    "#grid(",
    "  columns: (1fr, 1fr),",
    "  column-gutter: 16pt,",
    render_cv_typst_detail_block(
      "Certifications",
      profile$additional$certifications,
      trailing_comma = TRUE
    ),
    render_cv_typst_detail_block("Languages", profile$additional$languages),
    ")"
  )

  paste(
    c(
      readLines(here::here("typst-preamble.typ"), warn = FALSE),
      "",
      header,
      "",
      summary_block,
      "",
      "#section([Experience])",
      "",
      selected_block,
      "",
      "#pagebreak(weak: true)",
      "",
      "#section([Earlier Experience])",
      "",
      earlier_block,
      "",
      "#section([Education])",
      "",
      education_block,
      "",
      "#section([Technical Skills])",
      "",
      skills_block,
      "",
      additional_block
    ),
    collapse = "\n"
  )
}
