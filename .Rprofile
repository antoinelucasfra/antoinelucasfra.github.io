# R environment for this site: renv, restored from renv.lock.
#
# Repos point at a dated Posit Public Package Manager snapshot so the versions
# pinned in renv.lock stay downloadable: `/cran/latest` only serves current
# versions, which is why pinned packages eventually fail to restore.
# Bump the date deliberately when updating dependencies.
#
# The user agent tells Posit Package Manager which platform to serve binaries
# for, so CI restores prebuilt Linux binaries instead of compiling from source.
options(
  repos = c(
    RSPM = "https://packagemanager.posit.co/cran/2026-10-15",
    CRAN = "https://cloud.r-project.org"
  ),
  HTTPUserAgent = sprintf(
    "R/%s R (%s)",
    getRversion(),
    paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
  )
)

source("renv/activate.R")
