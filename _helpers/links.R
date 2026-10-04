# Shared HTML link helpers used by the homepage, the about page and the CVs.
external_link_attrs <- list(target = "_blank", rel = "noopener noreferrer")

# External anchor carrying the shared link attributes; the label defaults to the
# href without its scheme.
external_link <- function(href, text = sub("^https://", "", href), icon = NULL) {
  children <- list(text)
  if (!is.null(icon)) {
    children <- c(list(htmltools::tags$i(class = paste("bi", icon))), children)
  }
  do.call(htmltools::tags$a, c(list(href = href), external_link_attrs, children))
}

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
