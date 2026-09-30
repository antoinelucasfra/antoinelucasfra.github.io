# Self-check for the CV variant overlay in _helpers/profile_render.R.
# Run from the repo root: Rscript _helpers/test-profile-variant.R
source(here::here("_helpers", "profile_render.R"))

profile <- list(
  identity = list(title = "base", cv_pdf = "cv.pdf"),
  summary = list(cv = "base summary", cv_biostat = "biostat summary"),
  skills = list(
    list(label = "A", items = "a", order = 4),
    list(label = "B", items = "b", order = 1, order_biostat = 4),
    list(label = "C", items = "c", order = 4, order_biostat = 1)
  ),
  experience = list(
    list(role = "R1", bullets = "base bullet", bullets_biostat = c("s1", "s2")),
    list(role = "R2", bullets = "shared bullet")
  )
)

ai <- apply_variant(profile, "ai")
biostat <- apply_variant(profile, "biostat")

stopifnot(
  # variant-specific key wins, unsuffixed key survives when there is no override
  identical(ai$summary$cv, "base summary"),
  is.null(ai$summary$cv_biostat),
  identical(biostat$summary$cv, "biostat summary"),
  # nested override inside an unnamed list of entries
  identical(ai$experience[[1]]$bullets, "base bullet"),
  identical(biostat$experience[[1]]$bullets, c("s1", "s2")),
  identical(biostat$experience[[2]]$bullets, "shared bullet"),
  # entry order and unnamed shape preserved
  identical(vapply(biostat$experience, function(entry) entry$role, character(1)), c("R1", "R2")),
  # renamed keys do not leak into the rendered profile
  identical(names(biostat$identity), c("title", "cv_pdf")),
  identical(sort(names(ai$summary)), "cv"),
  # skills order resolution (stable on ties)
  identical(order_skills(ai$skills)[[1]]$label, "B"),
  identical(order_skills(biostat$skills)[[1]]$label, "C"),
  identical(
    vapply(order_skills(ai$skills), function(group) group$label, character(1)),
    c("B", "A", "C")
  )
)

# The real profile must resolve both variants without leaking suffixed keys.
real <- load_profile("biostat")
stopifnot(
  !any(grepl("_biostat$", unlist(lapply(real, names)))),
  !identical(real$identity$title, load_profile()$identity$title),
  length(real$skills) == length(load_profile()$skills)
)

# Regression guard: a YAML sequence item written as `- text: more text` parses as a
# MAPPING, so unlist() keeps the left half as a name and the renderers drop it (they
# print values only). Free-text list items must stay plain scalars: quote any text
# containing ": ".
plain_strings <- function(x) all(is.null(names(x)))
for (variant in cv_variants) {
  resolved <- load_profile(variant)
  for (entry in resolved$experience) {
    if (!plain_strings(entry$bullets)) {
      stop(
        "bullet written as a YAML mapping, losing its text before ': ' — role: ",
        entry$role
      )
    }
  }
  for (group in resolved$skills) {
    if (!plain_strings(group$items)) {
      stop("skill item written as a YAML mapping — group: ", group$label)
    }
  }
}

cat("OK: variant overlay behaves as specified\n")
