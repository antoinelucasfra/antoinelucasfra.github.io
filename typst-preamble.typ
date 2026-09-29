// ── Color palette ─────────────────────────────────────────────────────────────
#let navy  = rgb("#10243E")
#let gold  = rgb("#B68A2E")
#let slate = rgb("#5B6675")
#let mist  = rgb("#F4F5F7")

// ── Global rules ──────────────────────────────────────────────────────────────
#set text(fill: navy)
#set par(justify: false, leading: 0.7em)
#set list(indent: 0pt, body-indent: 1.2em, spacing: 3pt)
#show link: set text(fill: navy)

// ── Helpers ───────────────────────────────────────────────────────────────────

#let section(title) = {
  v(12pt)
  text(weight: "bold", size: 11pt, fill: navy)[#title]
  v(3pt)
  line(length: 100%, stroke: (paint: gold, thickness: 0.75pt))
  v(7pt)
}

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
