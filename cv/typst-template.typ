// Minimal Quarto Typst template for the CV.
// Bypasses the default article wrapper (no floating title block, no brand fonts).
// All layout is handled by typst-preamble.typ + the raw typst block in cv/typst-*.qmd.

#let article(
  lang: "en",
  region: "US",
  doc,
) = {
  set text(lang: lang, region: region)
  doc
}
