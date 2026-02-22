"""
Generate description fields for data/resources.txt.
Each entry gets a 1-sentence description derived from title, type, language, category.
"""

import re

INPUT = "/home/tonio/project/antoinelucasfra.github.io/data/resources.txt"
OUTPUT = "/home/tonio/project/antoinelucasfra.github.io/data/resources.txt"


def parse_entries(text):
    """Parse the flat YAML-like entries into dicts."""
    entries = []
    blocks = re.split(r"(?:^|\n)---\n", text)
    for block in blocks:
        block = block.strip()
        if not block:
            continue
        entry = {}
        for line in block.splitlines():
            m = re.match(r'^(\w+):\s+"?(.*?)"?\s*$', line)
            if m:
                entry[m.group(1)] = m.group(2)
        if "title" in entry:
            entries.append(entry)
    return entries


def type_phrase(t):
    phrases = {
        "Book": "A book",
        "Blog": "A blog",
        "Website": "A website",
        "Package": "An R/Python package",
        "Course": "An online course",
        "Video": "A video",
        "Paper": "A paper",
        "Journal": "A journal",
        "Community": "A community resource",
        "Repository": "A code repository",
        "Forum": "A community forum",
        "Conference": "A conference resource",
        "Tool": "A tool",
        "Podcast": "A podcast",
        "Newsletter": "A newsletter",
        "Cheatsheet": "A cheatsheet",
    }
    return phrases.get(t, "A resource")


def lang_phrase(lang):
    if lang == "R":
        return "for R"
    elif lang == "Python":
        return "for Python"
    elif lang == "Other":
        return ""
    return f"for {lang}"


def category_phrase(cat):
    """Turn semicolon-separated categories into a readable phrase."""
    if not cat:
        return ""
    parts = [p.strip() for p in cat.split(";") if p.strip()]
    # Filter out meta-tags like "French", "Tutorial", "Book", "Resources"
    filtered = [p for p in parts if p not in ("French", "Tutorial", "Book", "Resources", "Reference", "Interactive")]
    if not filtered:
        filtered = parts
    if len(filtered) == 1:
        return f"covering {filtered[0]}"
    elif len(filtered) == 2:
        return f"covering {filtered[0]} and {filtered[1]}"
    else:
        return f"covering {', '.join(filtered[:-1])}, and {filtered[-1]}"


def make_description(entry):
    title = entry.get("title", "")
    etype = entry.get("type", "Resource")
    lang = entry.get("language", "Other")
    cat = entry.get("category", "")

    tp = type_phrase(etype)
    lp = lang_phrase(lang)
    cp = category_phrase(cat)

    # Special cases for personal websites / blogs (name-only title)
    if etype in ("Blog", "Website") and re.match(r'^[A-Z][a-z]+ [A-Z][a-z]+', title) and not any(c in title for c in ["-", "–", ":"]):
        parts = [p.strip() for p in cat.split(";") if p.strip()]
        topic = parts[0] if parts else "data science"
        lp2 = lang_phrase(lang)
        if lp2:
            return f"Personal {etype.lower()} by {title} on {topic} {lp2}."
        return f"Personal {etype.lower()} by {title} on {topic}."

    # Compose sentence
    parts = [tp]
    if lp:
        parts.append(lp)
    if cp:
        parts.append(cp)
    sentence = " ".join(parts)

    # Add title context if it is descriptive enough
    if len(title) > 5 and not title.startswith("http"):
        sentence = f"{sentence} — {title}."
    else:
        sentence += "."

    return sentence


def format_entry(entry, desc):
    title = entry.get("title", "")
    etype = entry.get("type", "")
    link = entry.get("link", "")
    lang = entry.get("language", "")
    cat = entry.get("category", "")
    return (
        f'---\n'
        f'title: "{title}"\n'
        f'type: "{etype}"\n'
        f'link: "{link}"\n'
        f'language: "{lang}"\n'
        f'category: "{cat}"\n'
        f'description: "{desc}"\n'
        f'---'
    )


def main():
    with open(INPUT, "r", encoding="utf-8") as f:
        text = f.read()

    entries = parse_entries(text)
    print(f"Parsed {len(entries)} entries")

    output_parts = []
    for entry in entries:
        desc = make_description(entry)
        # Escape double quotes in description
        desc = desc.replace('"', "'")
        output_parts.append(format_entry(entry, desc))

    output = "\n".join(output_parts) + "\n"

    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(output)

    print(f"Written {len(entries)} entries with descriptions to {OUTPUT}")
    # Show a few samples
    for i in [0, 5, 20, 50, 100]:
        if i < len(entries):
            e = entries[i]
            d = make_description(e)
            print(f"\n[{i}] {e.get('title')} ({e.get('type')}, {e.get('category')})")
            print(f"  → {d}")


if __name__ == "__main__":
    main()
