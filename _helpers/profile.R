# Shared profile layer: reads cv/profile.yml for the homepage and the About page.
# Sourced by _helpers/site-render.R and by the pages that render it.
load_profile <- function(path = here::here("cv", "profile.yml")) {
  yaml::read_yaml(path)
}
