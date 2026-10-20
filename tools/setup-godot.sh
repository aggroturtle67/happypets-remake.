#!/usr/bin/env bash
set -euo pipefail
pfotenstube_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$pfotenstube_root"
export XDG_DATA_HOME=/workspace/.pfotenstube-runtime/data
export XDG_CONFIG_HOME=/workspace/.pfotenstube-runtime/config
export XDG_CACHE_HOME=/workspace/.pfotenstube-runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
case "$(godot --version)" in
  4.6.3.*) ;;
  *) printf '%s\n' 'This setup requires the preinstalled Godot 4.6.3 editor.' >&2; exit 1 ;;
esac
python3 tools/install_godot_templates.py
godot --headless --path godot --editor --import --quit
pfotenstube_test_data="$(mktemp -d /tmp/pfotenstube-godot-test.XXXXXX)"
trap 'rm -rf -- "$pfotenstube_test_data"' EXIT
XDG_DATA_HOME="$pfotenstube_test_data" timeout 60s godot --headless --path godot --script tests/run_tests.gd 2>&1 | tee "$pfotenstube_test_data/test.log"
rg -q '^GODOT TEST RESULT: [0-9]+ passed, 0 failed$' "$pfotenstube_test_data/test.log"
if rg -q '^ERROR:|^SCRIPT ERROR:' "$pfotenstube_test_data/test.log"; then
  printf '%s\n' 'Godot emitted an error during validation.' >&2
  exit 1
fi
mkdir -p godot/builds/windows godot/builds/linux
godot --headless --path godot --export-release 'Windows Desktop'
godot --headless --path godot --export-release 'Linux Smoke Test'
chmod u+x godot/builds/linux/Pfotenstube.x86_64
XDG_DATA_HOME="$pfotenstube_test_data" godot/builds/linux/Pfotenstube.x86_64 --headless --quit-after 20 2>&1 | tee "$pfotenstube_test_data/release.log"
if rg -q '^ERROR:|^SCRIPT ERROR:' "$pfotenstube_test_data/release.log"; then
  printf '%s\n' 'The exported runtime emitted an error.' >&2
  exit 1
fi
python3 tools/package_windows.py
