// CV layout — the only source of the CVs: cv/profile.yml, this preamble and
// cv/render.R. job-search builds tailored CVs from here.


// ── Palette ──────────────────────────────────────────────────────────────────
#let navy = rgb("#10243E")
#let gold = rgb("#B68A2E")
#let slate = rgb("#5B6675")
#let mist = rgb("#F4F5F7")

// ── Page ─────────────────────────────────────────────────────────────────────
// Quarto's typst template defaults to 1.25in margins, which is what pushed the
// CV to three pages. These are the values the site sets under format.typst, kept
// here so a CV renders identically with or without Quarto.
#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.8cm, right: 1.8cm),
  numbering: none,
  fill: white,
)

// Explicit font: Typst's bundled serif is the only family guaranteed everywhere
// (the site renders on CI, tailored CVs render locally).
#set text(font: "New Computer Modern", size: 10pt, fill: navy)
#set par(leading: 0.68em, spacing: 0.68em)
#set list(indent: 0pt, body-indent: 1.15em, spacing: 2.8pt)
#show link: set text(fill: navy)

// Every grid is an entry or a skill row: keep it whole instead of splitting it
// across a page boundary.
#show grid: block.with(breakable: false)

// ── Helpers ───────────────────────────────────────────────────────────────────
// `breakable: false` keeps a section title with its rule instead of orphaning
// them at the bottom of a page.
#let section(title) = block(breakable: false, above: 12pt, below: 0pt)[
  #text(weight: "bold", size: 11pt, fill: navy)[#title]
  #v(3pt)
  #line(length: 100%, stroke: (paint: gold, thickness: 0.75pt))
  #v(7pt)
]

#let entry(role, org, period, items) = {
  grid(
    columns: (1fr, auto),
    column-gutter: 10pt,
    block(below: 0pt)[
      #text(weight: "bold", size: 10.2pt)[#role]
      #v(2pt)
      #text(style: "italic", size: 9pt, fill: slate)[#org]
    ],
    align(right + top)[
      #text(size: 8.8pt, fill: slate)[#period]
    ],
  )
  v(4pt)
  block(above: 0pt, below: 0pt)[#items]
  v(7pt)
}

#let intern_entry(role, org, period, summary) = {
  grid(
    columns: (1fr, auto),
    column-gutter: 10pt,
    block(below: 0pt)[
      #text(weight: "bold", size: 9.5pt)[#role]
      #h(4pt)
      #text(size: 9pt, fill: slate)[— #org]
      #v(1pt)
      #text(size: 9pt)[#summary]
    ],
    align(right + top)[
      #text(size: 8.5pt, fill: slate)[#period]
    ],
  )
  v(6pt)
}

#let edu_entry(degree, school, year) = {
  block(below: 6pt)[
    #text(weight: "bold", size: 9.5pt)[#degree]
    #h(3pt)
    #text(size: 8.8pt, fill: slate)[(#year)]
    #v(1pt)
    #text(style: "italic", size: 8.9pt, fill: slate)[#school]
  ]
}

#let skill_row(label, value) = {
  block(below: 3pt)[
    #grid(
      columns: (2.7cm, 1fr),
      column-gutter: 8pt,
      text(weight: "bold", size: 8.9pt, fill: navy)[#label],
      text(size: 8.9pt)[#value],
    )
  ]
}
