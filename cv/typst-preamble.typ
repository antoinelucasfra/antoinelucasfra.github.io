// CV Typst layer. The layout is the vendored modern-cv 0.10.0
// (cv/modern-cv.typ, MIT, https://github.com/ptsouchlos/modern-cv), fed from
// cv/profile.yml by cv/render.R. Imports resolve relative to this directory.
#import "modern-cv.typ": *

// The site brand injects Space Grotesk headings and a 0.45em heading leading
// ahead of this file; re-assert the font and leading or the CVs spill to page 3.
#set par(leading: 0.65em)
#show heading: set par(leading: 0.65em)
#show heading: set text(font: "New Computer Modern")
