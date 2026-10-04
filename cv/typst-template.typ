// Minimal Quarto Typst template for the CV.
// Bypasses the default article wrapper (no floating title block, no brand fonts).
// All layout is handled by typst-preamble.typ + the raw typst block in cv/typst-*.qmd.

#let article(
  doc,
  lang: "en",
  region: "US",
) = {
  set text(lang: lang, region: region)
  doc
}
