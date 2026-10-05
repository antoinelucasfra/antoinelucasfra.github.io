# Homepage and about-page sections. Sourced by index.qmd and about.qmd.
source(here::here("_helpers", "profile.R"))
source(here::here("_helpers", "links.R"))

render_homepage <- function(profile) {
  identity <- profile$identity
  current_role <- profile$home$current_role
  n_posts <- length(list.dirs(here::here("posts"), recursive = FALSE))
  stats <- c(
    profile$home$stats,
    list(list(value = paste0(n_posts, "+"), label = "field notes published"))
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
          icon_link("/cv/", "bi-file-earmark-text", "CV", extra_class = "hero-link-cv")
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
      ),
      htmltools::tags$p(class = "availability", identity$availability)
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
            " · ",
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
      icon_link("/cv/", "bi-file-earmark-text", "Full CV")
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
    htmltools::tags$p(class = "availability", identity$availability),
    htmltools::tags$ul(
      htmltools::tags$li(
        htmltools::tags$strong("Email"),
        ": ",
        htmltools::tags$a(href = paste0("mailto:", identity$email), identity$email)
      ),
      htmltools::tags$li(
        htmltools::tags$strong("LinkedIn"),
        ": ",
        external_link(identity$linkedin)
      ),
      htmltools::tags$li(
        htmltools::tags$strong("GitHub"),
        ": ",
        external_link(identity$github)
      ),
      htmltools::tags$li(
        htmltools::tags$strong("Fosstodon"),
        ": ",
        external_link(identity$mastodon, "@antoineloucass")
      )
    ),
    htmltools::tags$p(
      "Content on this site is licensed under ",
      external_link(
        "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        "CC BY NC SA 4.0"
      ),
      " unless stated otherwise."
    )
  )
}
