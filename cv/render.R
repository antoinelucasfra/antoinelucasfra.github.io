# CV renderers (HTML and Typst), driven by cv/profile.yml.
# Sourced by the pages in cv/ and by the job-search repo (applications/_render.R).
source(here::here("_helpers", "profile.R"))
source(here::here("_helpers", "links.R"))

render_cv_entry_html <- function(role, organisation, period, body = NULL, class = "cv-entry") {
  htmltools::tags$div(
    class = class,
    htmltools::tags$div(
      class = "cv-entry-head",
      htmltools::tags$div(
        class = "cv-entry-meta",
        htmltools::tags$p(
          htmltools::tags$span(class = "cv-role", role),
          htmltools::tags$span(class = "cv-org", organisation)
        )
      ),
      htmltools::tags$p(class = "cv-period", period)
    ),
    body
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
          htmltools::tags$a(
            href = paste0("mailto:", identity$email),
            htmltools::tags$i(class = "bi bi-envelope-fill"),
            identity$email
          ),
          external_link(identity$linkedin, icon = "bi-linkedin"),
          external_link(identity$github, icon = "bi-github"),
          external_link(identity$website, icon = "bi-globe"),
          external_link(
            profile$identity$cv_pdf %||% "cv.pdf",
            "Download PDF",
            icon = "bi-file-earmark-pdf"
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
    lapply(selected_experience, function(entry) {
      body <- if (is.null(entry$bullets)) {
        htmltools::tags$p(class = "cv-inline-text", entry$summary)
      } else {
        htmltools::tags$ul(lapply(entry$bullets, function(item) htmltools::tags$li(item)))
      }
      render_cv_entry_html(entry$role, entry$organisation, entry$period, body)
    }),
    htmltools::tags$h2(class = "cv-section-title", "Earlier experience"),
    lapply(earlier_experience, function(entry) {
      body <- if (is.null(entry$bullets)) {
        htmltools::tags$p(class = "cv-inline-text", entry$summary)
      } else {
        htmltools::tags$ul(lapply(entry$bullets, function(item) htmltools::tags$li(item)))
      }
      render_cv_entry_html(entry$role, entry$organisation, entry$period, body)
    }),
    htmltools::tags$h2(class = "cv-section-title", "Education"),
    lapply(profile$education, function(entry) {
      render_cv_entry_html(entry$degree, entry$school, entry$year, class = "cv-entry cv-entry-edu")
    }),
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
      lapply(
        list(
          c("Certifications", profile$additional$certifications),
          c("Languages", profile$additional$languages)
        ),
        function(section) {
          htmltools::tags$div(
            class = "cv-inline-section",
            htmltools::tags$h2(class = "cv-section-title", section[[1]]),
            lapply(section[-1], function(item) htmltools::tags$p(class = "cv-inline-text", item))
          )
        }
      )
    )
  )
}

# Typst escape: with `fixed = TRUE` the replacement is literal, so each
# replacement carries exactly the backslashes Typst should see. Quadrupled
# backslashes emit `\\@`, which Typst reads as a reference (`@gmail.com`).
typst_escape <- function(text) {
  escaped <- gsub("\\", "\\\\", text, fixed = TRUE)
  escaped <- gsub("@", "\\@", escaped, fixed = TRUE)
  escaped <- gsub("[", "\\[", escaped, fixed = TRUE)
  escaped <- gsub("]", "\\]", escaped, fixed = TRUE)
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

# One `#fn(` + bracketed args + `)` emitter: every Typst helper below it takes
# plain text arguments.
typst_call <- function(fn, args) {
  c(
    paste0("#", fn, "("),
    vapply(args, function(arg) paste0("  ", typst_bracket(arg), ","), character(1)),
    ")"
  )
}

render_cv_typst_intern <- function(entry) {
  typst_call("intern_entry", list(entry$role, entry$organisation, entry$period, entry$summary))
}

render_cv_typst_education <- function(entry) {
  typst_call("edu_entry", list(entry$degree, entry$school, entry$year))
}

render_cv_typst_skill <- function(group) {
  typst_call("skill_row", list(group$label, paste(group$items, collapse = " · ")))
}

render_cv_typst_detail_block <- function(title, items) {
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

  c(block_lines, "  ],")
}

render_cv_typst <- function(profile, internships = c("keep", "drop")) {
  internships <- match.arg(internships)
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
      typst_escape(identity$email),
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
    "    #linebreak()",
    paste0(
      "    #text(size: 9pt)[#link(\"",
      identity$website,
      "\")[",
      typst_escape(sub("^https://", "", identity$website)),
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
  education_block <- unlist(lapply(profile$education, render_cv_typst_education), use.names = FALSE)
  skills_block <- unlist(lapply(profile$skills, render_cv_typst_skill), use.names = FALSE)

  # Emitted only when kept, so no empty "Earlier Experience" heading is left.
  earlier_section <- if (identical(internships, "drop") || !length(earlier_experience)) {
    character(0)
  } else {
    c(
      "#pagebreak(weak: true)",
      "",
      "#section([Earlier Experience])",
      "",
      unlist(lapply(earlier_experience, render_cv_typst_intern), use.names = FALSE)
    )
  }

  # Reader and ATS metadata; without it the PDF carries no name.
  metadata <- c(
    "#set document(",
    paste0(
      "  title: \"",
      gsub("\"", "\\\\\"", paste(identity$name, "—", identity$title), fixed = TRUE),
      "\","
    ),
    paste0("  author: \"", gsub("\"", "\\\\\"", identity$name, fixed = TRUE), "\","),
    "  date: none,",
    ")"
  )

  additional_block <- c(
    "#section([Additional Information])",
    "",
    "#grid(",
    "  columns: (1fr, 1fr),",
    "  column-gutter: 16pt,",
    render_cv_typst_detail_block("Certifications", profile$additional$certifications),
    render_cv_typst_detail_block("Languages", profile$additional$languages),
    ")"
  )

  paste(
    c(
      readLines(here::here("cv", "typst-preamble.typ"), warn = FALSE),
      "",
      metadata,
      "",
      header,
      "",
      summary_block,
      "",
      "#section([Experience])",
      "",
      selected_block,
      "",
      earlier_section,
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
