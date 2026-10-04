// Minimal Quarto Typst template for the CV.
// Bypasses the default article wrapper (no floating title block, no brand fonts).
// All layout is handled by typst-preamble.typ + the cv-typst.qmd raw typst block.

#let article(
  lang: "en",
  region: "US",
  font: none,
  fontsize: 10pt,
  doc,
) = {
  set text(lang: lang, region: region, size: fontsize)
  set text(font: font) if font != none
  doc
}
