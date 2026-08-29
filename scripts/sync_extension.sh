#!/usr/bin/env bash
# Sync canonical extension (website) -> distribution targets:
#   1. standalone Quarto extension repo   (quarto-al-brand/)
#   2. R package bundle                   (albrand/)
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=_extensions/antoinelucasfra/al-brand
cp "$SRC"/*.scss "$SRC"/*.yml quarto-al-brand/_extensions/al-brand/
cp "$SRC"/*.scss "$SRC"/*.yml albrand/inst/quarto/_extensions/al-brand/
echo "synced $SRC -> quarto-al-brand/ + albrand/"
