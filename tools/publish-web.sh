#!/usr/bin/env bash
set -euo pipefail
web_project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$web_project_root"
if [ "${1:-}" != "--no-build" ]; then
  bash tools/build-web.sh
fi
web_output="$web_project_root/godot/builds/web"
web_basename="$(sed -n 's/.*"executable":"\([^"]*\)".*/\1/p' "$web_output/index.html")"
if [[ ! "$web_basename" =~ ^pfotenstube-[0-9a-f]{16}$ ]] || [ ! -s "$web_output/$web_basename.wasm" ] || [ ! -s "$web_output/$web_basename.pck" ]; then
  printf '%s\n' 'A complete, versioned Godot web export is required.' >&2
  exit 1
fi
web_origin="$(git remote get-url origin)"
web_publish="$(mktemp -d /tmp/pfotenstube-web-publish.XXXXXX)"
if git ls-remote --exit-code --heads "$web_origin" gh-pages > /dev/null; then
  git clone --depth 1 --branch gh-pages "$web_origin" "$web_publish"
  # Only the dedicated, generated website branch is replaced; its history remains.
  test "$(git -C "$web_publish" branch --show-current)" = gh-pages
  web_previous="$(sed -n 's/.*"executable":"\([^"]*\)".*/\1/p' "$web_publish/index.html")"
  git -C "$web_publish" rm -r --ignore-unmatch -- .
  if [[ "$web_previous" =~ ^pfotenstube-[0-9a-f]{16}$ ]]; then
    # A cached previous index.html can still load its own complete set of assets.
    git -C "$web_publish" restore --source=HEAD --staged --worktree -- "$web_previous.*"
  fi
else
  git init -b gh-pages "$web_publish"
  git -C "$web_publish" remote add origin "$web_origin"
fi
cp "$web_output/index.html" "$web_output/.nojekyll" "$web_output"/*.txt "$web_output/$web_basename".* "$web_publish/"
git -C "$web_publish" add --all
if ! git -C "$web_publish" diff --cached --quiet; then
  git -C "$web_publish" commit -m "Publish Godot browser build $web_basename"
  git -C "$web_publish" push origin gh-pages
fi
printf '%s\n' 'Website files are on gh-pages. GitHub Pages must use gh-pages / (root).'
git -C "$web_publish" rev-parse HEAD
