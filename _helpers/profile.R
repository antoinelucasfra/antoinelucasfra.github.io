# Shared profile layer: reads cv/profile.yml and applies a CV variant overlay.
# Sourced by cv/render.R, _helpers/site-render.R and cv/test-profile-variant.R.
#' CV variants share one profile: `cv/profile.yml`.
cv_variants <- c("ai", "biostat")

load_profile <- function(variant = NULL, path = here::here("cv", "profile.yml")) {
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
