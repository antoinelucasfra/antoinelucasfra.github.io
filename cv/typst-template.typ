// Minimal Quarto Typst template for the CV: article() wrapper, no title block.
// Layout comes from the vendored modern-cv via the raw typst block in render.R.

#let article(
  doc,
  lang: "en",
  region: "US",
) = {
  set text(lang: lang, region: region)
  doc
}
