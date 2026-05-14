#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

tex_file="${1:-main.tex}"

mkdir -p build

if command -v latexmk >/dev/null 2>&1; then
  latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=build "$tex_file"
  exit 0
fi

if command -v xelatex >/dev/null 2>&1; then
  xelatex -interaction=nonstopmode -halt-on-error -output-directory=build "$tex_file"
  xelatex -interaction=nonstopmode -halt-on-error -output-directory=build "$tex_file"
  exit 0
fi

tectonic_bin="$("./ensure_tectonic.sh")"
"$tectonic_bin" -o build -r 1 "$tex_file"
