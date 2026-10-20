#!/usr/bin/env bash
set -euo pipefail
web_project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$web_project_root"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.pfotenstube-runtime/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.pfotenstube-runtime/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.pfotenstube-runtime/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
case "$(godot --version)" in
  4.6.3.*) ;;
  *) printf '%s\n' 'Godot 4.6.3 is required.' >&2; exit 1 ;;
esac
python3 tools/install_godot_templates.py --web
web_stage="$(mktemp -d /tmp/pfotenstube-web-export.XXXXXX)"
trap 'rm -r -- "$web_stage"' EXIT
godot --headless --path godot --editor --import --quit > "$web_stage/import.log" 2>&1
if rg -q '^ERROR:|^SCRIPT ERROR:' "$web_stage/import.log"; then
  cat "$web_stage/import.log"
  exit 1
fi
web_build_id="$(git ls-files -z --cached --others --exclude-standard godot tools/build-web.sh | sort -zu | xargs -0 sha256sum | sha256sum | cut -c1-16)"
web_basename="pfotenstube-$web_build_id"
godot --headless --path godot --export-release Web "$web_stage/$web_basename.html" > "$web_stage/export.log" 2>&1
if rg -q '^ERROR:|^SCRIPT ERROR:' "$web_stage/export.log"; then
  cat "$web_stage/export.log"
  exit 1
fi
mv "$web_stage/$web_basename.html" "$web_stage/index.html"
cp godot/web/.nojekyll godot/licenses/*.txt "$web_stage/"
mkdir -p godot/builds/web
cp "$web_stage/index.html" "$web_stage/.nojekyll" "$web_stage"/*.txt "$web_stage/$web_basename".* godot/builds/web/
printf 'Web build %s is ready in godot/builds/web/\n' "$web_build_id"
