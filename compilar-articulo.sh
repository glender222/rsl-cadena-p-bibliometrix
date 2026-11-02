#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$project_dir/articulo"
image_name="rsl-latex:trixie"

if [[ "$#" -ne 0 ]]; then
    printf 'Uso: %s\n' "$0" >&2
    exit 2
fi

if ! docker image inspect "$image_name" >/dev/null 2>&1; then
    docker build -f "$project_dir/Dockerfile.latex" -t "$image_name" "$project_dir"
fi

mkdir -p "$source_dir/build"
docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --mount "type=bind,src=$source_dir,dst=/work" \
    --workdir /work \
    "$image_name" \
    latexmk -pdf -synctex=1 -interaction=nonstopmode -halt-on-error \
    -file-line-error -outdir=build manuscrito.tex

printf 'PDF: %s\n' "$source_dir/build/manuscrito.pdf"
