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

# Typst string literal: quote and escape what Typst treats specially inside "...".
typst_string <- function(text) {
  escaped <- gsub("\\", "\\\\", text, fixed = TRUE)
  escaped <- gsub("\"", "\\\"", escaped, fixed = TRUE)
  paste0("\"", escaped, "\"")
}

# Typst content: escape the characters that would otherwise be parsed as markup.
typst_content <- function(text) {
  escaped <- gsub("\\", "\\\\", text, fixed = TRUE)
  for (char in c("#", "[", "]", "*", "_", "`", "$", "<", ">", "@", "~")) {
    escaped <- gsub(char, paste0("\\", char), escaped, fixed = TRUE)
  }
  escaped
}

render_cv_typst_entry_head <- function(title, location, description) {
  paste0(
    "#resume-entry(title: ", typst_string(title),
    ", location: ", typst_string(location),
    ", description: ", typst_string(description), ")"
  )
}

render_cv_typst_item <- function(lines, bullets = TRUE) {
  lines <- unlist(lines)
  if (!length(lines)) {
    return(character(0))
  }
  if (isTRUE(bullets)) {
    c("#resume-item[", paste0("  - ", typst_content(lines)), "]")
  } else {
    paste0("#resume-item[", typst_content(lines), "]")
  }
}

render_cv_typst_entry <- function(entry) {
  c(
    render_cv_typst_entry_head(entry$role, entry$period, entry$organisation),
    render_cv_typst_item(entry$bullets)
  )
}

# Internships carry one line each, so they render as a compact bullet list
# rather than as full entries with a header, an organisation line and a summary.
render_cv_typst_interns <- function(entries) {
  c(
    "#resume-item[",
    vapply(
      entries,
      function(entry) {
        paste0(
          "  - *", typst_content(entry$role), "*, ",
          typst_content(entry$organisation),
          " (", typst_content(entry$period), "). ",
          typst_content(entry$summary)
        )
      },
      character(1)
    ),
    "]"
  )
}

render_cv_typst_skill <- function(group) {
  paste0(
    "#resume-skill-item(",
    typst_string(group$label),
    ", (",
    paste0(typst_string(group$items), collapse = ", "),
    ",))"
  )
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

  name_parts <- strsplit(identity$name, " ", fixed = TRUE)[[1]]
  last_name <- paste(name_parts[-1], collapse = " ")

  # modern-cv expects bare handles and prefixes them itself, so the full URLs
  # from the profile are passed as custom contacts instead.
  handle <- function(url, prefix) sub("/$", "", sub(prefix, "", url))
  contacts <- c(
    paste0(
      "(text: ", typst_string(identity$email),
      ", link: ", typst_string(paste0("mailto:", identity$email)), ")"
    ),
    paste0(
      "(text: ", typst_string(paste0("in/", handle(identity$linkedin, "^.*/in/"))),
      ", link: ", typst_string(identity$linkedin), ")"
    ),
    paste0(
      "(text: ", typst_string(paste0("github.com/", handle(identity$github, "^.*github[.]com/"))),
      ", link: ", typst_string(identity$github), ")"
    ),
    paste0(
      "(text: ", typst_string(sub("^https?://", "", identity$website)),
      ", link: ", typst_string(identity$website), ")"
    )
  )

  header <- c(
    "#show: resume.with(",
    "  author: (",
    paste0("    firstname: ", typst_string(name_parts[[1]]), ","),
    paste0("    lastname: ", typst_string(last_name), ","),
    paste0("    positions: (", typst_string(identity$title), ",),"),
    paste0("    address: ", typst_string(identity$location_full), ","),
    "    custom: (",
    paste0("      ", contacts, collapse = ",\n"),
    "    ),",
    "  ),",
    "  profile-picture: none,",
    "  date: \"\",",
    "  accent-color: rgb(\"#10243E\"),",
    "  font: \"New Computer Modern\",",
    "  header-font: \"New Computer Modern\",",
    "  contact-items-separator: text(\" · \"),",
    "  paper-size: \"a4\",",
    "  show-address-icon: false,",
    paste0("  description: ", typst_string(identity$title), ","),
    paste0(
      "  keywords: (",
      paste0(typst_string(strsplit(identity$sectors, " · ")[[1]]), collapse = ", "),
      ",),"
    ),
    ")",
    paste0(
      "#set document(title: ",
      typst_string(paste0("Antoine Lucas, ", identity$title %||% "CV")),
      ")"
    )
  )

  sections <- c(
    "= Summary",
    render_cv_typst_item(profile$summary$cv, bullets = FALSE),
    "",
    "= Experience",
    unlist(lapply(selected_experience, render_cv_typst_entry), use.names = FALSE),
    "",
    if (identical(internships, "keep") && length(earlier_experience)) {
      c(
        "= Earlier Experience",
        render_cv_typst_interns(earlier_experience),
        ""
      )
    },
    "= Education",
    vapply(
      profile$education,
      function(entry) {
        render_cv_typst_entry_head(entry$degree, entry$year, entry$school)
      },
      character(1)
    ),
    "",
    "= Skills & credentials",
    vapply(profile$skills, render_cv_typst_skill, character(1)),
    render_cv_typst_skill(list(
      label = "Certifications",
      items = profile$additional$certifications
    )),
    render_cv_typst_skill(list(
      label = "Languages",
      items = profile$additional$languages
    ))
  )

  paste(
    c(
      readLines(here::here("cv", "typst-preamble.typ"), warn = FALSE),
      "",
      header,
      "",
      sections
    ),
    collapse = "\n"
  )
}
